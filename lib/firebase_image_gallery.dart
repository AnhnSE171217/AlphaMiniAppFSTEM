import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:logger/logger.dart'; // Add this import
import 'websocket_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:async';

class FirebaseImageGallery extends StatefulWidget {
  final WebSocketService? webSocketService;

  const FirebaseImageGallery({super.key, this.webSocketService});

  @override
  State<FirebaseImageGallery> createState() => _FirebaseImageGalleryState();
}

class _FirebaseImageGalleryState extends State<FirebaseImageGallery>
    with SingleTickerProviderStateMixin {
  final Logger logger = Logger(); // Add this line
  final String baseUrl =
      'https://console.firebase.google.com/u/0/project/alphamini-a291d/storage/alphamini-a291d.firebasestorage.app/files/~2Fimages';
  List<String> imageUrls = [];
  bool isLoading = true;
  String errorMessage = '';
  bool isDownloading = false;
  String? downloadedImagePath;

  late AnimationController _refreshController;
  bool _isRefreshing = false;

  // Add a subscription variable to track the WebSocket stream
  StreamSubscription? _webSocketSubscription;
  // Add a mounted check flag
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _loadImages();

    // Store the subscription to properly dispose it later
    if (widget.webSocketService != null) {
      _webSocketSubscription = widget.webSocketService!.messageStream.listen((
        message,
      ) {
        logger.i(
          'Received WebSocket message: $message',
        ); // Replace print with logger.i
        if (_isMounted) {
          _handleWebSocketMessage(message);
        }
      });
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    // Cancel the WebSocket subscription
    _webSocketSubscription?.cancel();

    // Only send "Close" if webSocketService exists
    if (widget.webSocketService != null) {
      widget.webSocketService!.sendMessage("Close");
    }

    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadImages() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
      imageUrls = [];
      _isRefreshing = true;
    });

    _refreshController.repeat();

    try {
      // Initialize Firebase if not already done elsewhere
      // await Firebase.initializeApp();

      // Reference to the images folder
      final storageRef = FirebaseStorage.instance.ref().child('images');

      // List all items in the directory
      final ListResult result = await storageRef.listAll();

      // Get download URLs for all items
      for (var item in result.items) {
        String downloadUrl = await item.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      if (mounted) {
        setState(() {
          isLoading = false;
          _isRefreshing = false;
        });
      }
      _refreshController.stop();
      _refreshController.reset();
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to load images: $e';
          isLoading = false;
          _isRefreshing = false;
        });
      }
      _refreshController.stop();
      _refreshController.reset();
    }
  }

  // Handle WebSocket messages
  void _handleWebSocketMessage(String message) {
    if (!mounted) return;

    if (message.contains('http')) {
      // Assuming the WebSocket sends a Firebase link when a photo is captured
      setState(() {
        imageUrls.clear();
        imageUrls.add(message); // Add the Firebase image URL
      });
    } else if (message == "photoCaptured") {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo captured successfully!')),
        );
      }
      _loadImages(); // Reload images after capturing
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Received message: $message')));
      }
    }
  }

  Future<void> _downloadImage(String imageUrl) async {
    setState(() {
      isDownloading = true;
      errorMessage = '';
    });

    try {
      bool hasPermission = await _requestPermissions();
      if (!hasPermission) {
        setState(() {
          errorMessage = 'Storage permission is required to save images';
          isDownloading = false;
        });
        return;
      }

      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        String? contentType = response.headers['content-type'];
        if (contentType != null && contentType.startsWith('image/')) {
          Directory? targetDir;
          String locationDescription = "Unknown location";

          if (Platform.isAndroid) {
            final List<String> possiblePaths = [
              '/storage/emulated/0/Download',
              '/storage/self/primary/Download',
              '/sdcard/Download',
            ];

            for (String path in possiblePaths) {
              final dir = Directory(path);
              if (await dir.exists()) {
                targetDir = dir;
                locationDescription = "Downloads folder";
                break;
              }
            }

            if (targetDir == null) {
              targetDir = await getExternalStorageDirectory();
              locationDescription = "External storage";

              if (targetDir == null) {
                targetDir = await getApplicationDocumentsDirectory();
                locationDescription = "App documents folder";
              }
            }
          } else {
            targetDir = await getApplicationDocumentsDirectory();
            locationDescription = "Documents folder";
          }

          String fileName =
              'firebase_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
          String filePath = '${targetDir.path}/$fileName';

          try {
            File file = File(filePath);
            await file.writeAsBytes(response.bodyBytes);

            setState(() {
              downloadedImagePath = filePath;
              isDownloading = false;
            });

            _showDownloadSuccessDialog(locationDescription, filePath);
          } catch (writeError) {
            final appDir = await getApplicationDocumentsDirectory();
            final appFilePath = '${appDir.path}/$fileName';

            File appFile = File(appFilePath);
            await appFile.writeAsBytes(response.bodyBytes);

            setState(() {
              downloadedImagePath = appFilePath;
              isDownloading = false;
            });

            _showDownloadSuccessDialog(
              "App private storage (fallback)",
              appFilePath,
            );
          }
        } else {
          setState(() {
            errorMessage = 'The URL does not point to an image file';
            isDownloading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to download: HTTP ${response.statusCode}';
          isDownloading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Download error: $e';
        isDownloading = false;
      });
    }
  }

  Future<void> _shareImage(String imageUrl) async {
    setState(() {
      isDownloading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final fileName =
            'firebase_image_share_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = '${tempDir.path}/$fileName';

        File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        await Share.shareXFiles([
          XFile(filePath),
        ], text: 'Check out this image from AlphaMini robot!');

        setState(() {
          isDownloading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to share: HTTP ${response.statusCode}';
          isDownloading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Share error: $e';
        isDownloading = false;
      });
    }
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        var status = await Permission.photos.request();
        return status.isGranted;
      } else {
        var status = await Permission.storage.request();
        return status.isGranted;
      }
    } else {
      var status = await Permission.photos.request();
      return status.isGranted;
    }
  }

  Future<bool> _isAndroid13OrHigher() async {
    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt >= 33; // Android 13 is API level 33
    }
    return false;
  }

  void _showDownloadSuccessDialog(String locationDescription, String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Download Complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('The image has been saved to your $locationDescription.'),
              const SizedBox(height: 16),
              const Text('File path:'),
              Text(
                filePath,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              if (locationDescription.contains("fallback") ||
                  locationDescription.contains("App"))
                const Text(
                  "Note: Image saved to app storage because system storage was unavailable. The image will be removed if the app is uninstalled.",
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _viewDownloadedImage();
              },
              child: const Text('View Image'),
            ),
          ],
        );
      },
    );
  }

  void _viewDownloadedImage() {
    if (downloadedImagePath == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                iconTheme: const IconThemeData(color: Colors.white),
                title: const Text('Downloaded Image'),
                elevation: 0,
              ),
              body: Center(child: Image.file(File(downloadedImagePath!))),
            ),
      ),
    );
  }

  void _sendCameraCommand() {
    if (widget.webSocketService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WebSocket service not available')),
      );
      return;
    }

    widget.webSocketService!.sendMessage("Capture");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Center(
          child: Text(
            '📸 Photo captured! Tap REFRESH to view it',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepOrange,
        title: const Text(
          'Image Gallery',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Go back',
        ),
        actions: [
          IconButton(
            icon: AnimatedBuilder(
              animation: _refreshController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _refreshController.value * 2.0 * 3.14159,
                  child: Icon(
                    Icons.refresh,
                    color: _isRefreshing ? Colors.amber : Colors.white,
                  ),
                );
              },
            ),
            onPressed: _isRefreshing ? null : _loadImages,
            tooltip: 'Refresh Images',
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed:
                imageUrls.isEmpty || isDownloading
                    ? null
                    : () => _shareImage(imageUrls[0]),
            tooltip: 'Share Image',
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed:
                imageUrls.isEmpty || isDownloading
                    ? null
                    : () => _downloadImage(imageUrls[0]),
            tooltip: 'Download Image',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepOrange.shade300, Colors.white],
          ),
        ),
        child: Stack(
          children: [
            _buildContent(),
            if (isDownloading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Downloading...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        height: 70.0,
        width: 70.0,
        child: FittedBox(
          child: FloatingActionButton(
            heroTag: 'camera',
            backgroundColor: Colors.purple,
            tooltip: 'Take Photo with Robot',
            onPressed:
                widget.webSocketService != null ? _sendCameraCommand : null,
            child: const Icon(Icons.camera_alt, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 4,
                backgroundColor: Colors.deepOrange.withAlpha(76),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading image...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      if (errorMessage.contains('Storage permission')) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 60),
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _requestPermissions,
                  child: const Text('Request Permission Again'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    openAppSettings();
                  },
                  child: const Text('Open App Settings'),
                ),
              ],
            ),
          ),
        );
      } else {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 60),
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadImages,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        );
      }
    }

    if (imageUrls.isEmpty) {
      return const Center(
        child: Text(
          'No images found',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _showFullImage(context, imageUrls[index]),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(51),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: imageUrls[index],
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Center(
                      child: CircularProgressIndicator(
                        color: Colors.deepOrange.shade300,
                      ),
                    ),
                errorWidget:
                    (context, url, error) => Icon(
                      Icons.broken_image,
                      color: Colors.red[300],
                      size: 48,
                    ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                iconTheme: const IconThemeData(color: Colors.white),
                elevation: 0,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                      _shareImage(imageUrl);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                      _downloadImage(imageUrl);
                    },
                  ),
                ],
              ),
              body: Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    placeholder:
                        (context, url) => const CircularProgressIndicator(
                          color: Colors.white,
                        ),
                    errorWidget:
                        (context, url, error) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style: TextStyle(
                                color: Colors.white.withAlpha(179),
                              ),
                            ),
                          ],
                        ),
                  ),
                ),
              ),
            ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class FirebaseImageGallery extends StatefulWidget {
  const FirebaseImageGallery({super.key});

  @override
  State<FirebaseImageGallery> createState() => _FirebaseImageGalleryState();
}

class _FirebaseImageGalleryState extends State<FirebaseImageGallery> {
  final String baseUrl =
      'https://storage.googleapis.com/alphamini-a291d.firebasestorage.app/Meo';
  List<String> imageUrls = [];
  bool isLoading = true;
  String errorMessage = '';
  bool isDownloading = false;
  String? downloadedImagePath;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      imageUrls = [];
    });

    try {
      // Just use the base URL directly
      imageUrls.add(baseUrl);

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load images: $e';
        isLoading = false;
      });
    }
  }

  // Add download functionality
  Future<void> _downloadImage(String imageUrl) async {
    setState(() {
      isDownloading = true;
      errorMessage = '';
    });

    try {
      // Get the image data
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        // Check if the content is an image
        String? contentType = response.headers['content-type'];
        if (contentType != null && contentType.startsWith('image/')) {
          // Save to gallery
          final result = await ImageGallerySaver.saveImage(
            response.bodyBytes,
            name: 'firebase_image_${DateTime.now().millisecondsSinceEpoch}',
          );

          // Also save to temp dir for preview
          Directory tempDir = await getTemporaryDirectory();
          String fileName =
              'firebase_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
          String filePath = '${tempDir.path}/$fileName';
          File file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          setState(() {
            downloadedImagePath = filePath;
            isDownloading = false;
          });

          // Show success message
          _showDownloadSuccessDialog("Photos gallery");
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

  void _showDownloadSuccessDialog(String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Download Complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('The image has been saved to your device.'),
              const SizedBox(height: 16),
              const Text('File location:'),
              Text(
                filePath,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
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
        ),
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

            // Download overlay
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'refresh',
              backgroundColor: Colors.blue.shade600,
              tooltip: 'Refresh',
              onPressed: _loadImages,
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
            const SizedBox(width: 16),
            FloatingActionButton(
              heroTag: 'download',
              backgroundColor: Colors.green,
              tooltip: 'Download Image',
              onPressed:
                  imageUrls.isEmpty || isDownloading
                      ? null
                      : () => _downloadImage(imageUrls[0]),
              child: const Icon(Icons.download, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (errorMessage.isNotEmpty) {
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

    if (imageUrls.isEmpty) {
      return const Center(
        child: Text(
          'No images found',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      );
    }

    // Replace the grid with a centered image display
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Firebase Storage Image',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: Offset(1.0, 1.0),
                  blurRadius: 3.0,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _showFullImage(context, imageUrls[0]),
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: imageUrls[0],
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  errorWidget:
                      (context, url, error) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            color: Colors.red[300],
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Image not available',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Directory URL cannot be displayed as image',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.touch_app, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Tap image to view full size',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.download, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Use download button to save image',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
                  // Add download button in full image view
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context); // Close the full image view
                      _downloadImage(imageUrl); // Start download
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
                                color: Colors.white.withOpacity(0.7),
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

import 'package:flutter/material.dart';
import 'package:flutterdemo0/bluetooth_screen.dart';
import 'package:flutterdemo0/speech_to_text_screen.dart';
import 'action_screen.dart';
import 'animated_feature_card.dart';
import 'dance_screen.dart';
import 'controller_screen.dart';
import 'expression_screen.dart';
import 'websocket_service.dart';
import 'firebase_image_gallery.dart';

// Add this custom page route class for custom animations
class CustomPageRoute extends PageRouteBuilder {
  final Widget page;

  CustomPageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = const Offset(1.0, 0.0);
          var end = Offset.zero;
          var curve = Curves.easeInOut;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
      );
}

class HomeScreen extends StatefulWidget {
  final WebSocketService webSocketService;

  const HomeScreen({super.key, required this.webSocketService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String connectionStatus = "Đang chờ kết nối...";

  @override
  void initState() {
    super.initState();
    widget.webSocketService.messageStream.listen(
      (message) {
        setState(() {
          connectionStatus = "Kết nối thành công!";
        });
      },
      onError: (error) {
        setState(() {
          connectionStatus = "Lỗi kết nối: $error";
        });
      },
    );
  }

  void _reloadConnection() {
    setState(() {
      connectionStatus = "Đang kết nối lại...";
    });
    widget.webSocketService.connect('ws://34.143.171.53:8001/ws');
  }

  void _goToActionScreen(BuildContext context) {
    widget.webSocketService.sendMessage("Action");
    Navigator.push(
      context,
      CustomPageRoute(
        page: ActionScreen(webSocketService: widget.webSocketService),
      ),
    );
  }

  void _goToDanceScreen(BuildContext context) {
    widget.webSocketService.sendMessage("Dance");
    Navigator.push(
      context,
      CustomPageRoute(
        page: DanceScreen(webSocketService: widget.webSocketService),
      ),
    );
  }

  void _goToControllerScreen(BuildContext context) {
    widget.webSocketService.sendMessage("Controller");
    Navigator.push(
      context,
      CustomPageRoute(
        page: ControllerScreen(webSocketService: widget.webSocketService),
      ),
    );
  }

  void _goToExpressionScreen(BuildContext context) {
    widget.webSocketService.sendMessage("Expression");
    Navigator.push(
      context,
      CustomPageRoute(
        page: ExpressionScreen(webSocketService: widget.webSocketService),
      ),
    );
  }

  void _goToBluetoothScreen(BuildContext context) {
    widget.webSocketService.sendMessage("Bluetooth");
    Navigator.push(context, CustomPageRoute(page: BluetoothConnectionPage()));
  }

  void _goToSpeechToTextScreen(BuildContext context) {
    widget.webSocketService.sendMessage("Voice");
    Navigator.push(
      context,
      CustomPageRoute(
        page: SpeechToTextScreen(webSocketService: widget.webSocketService),
      ),
    );
  }

  void _goToImageGallery(BuildContext context) {
    widget.webSocketService.sendMessage("Camera");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                FirebaseImageGallery(webSocketService: widget.webSocketService),
      ),
    );
  }

  // Helper methods to determine colors based on connection status
  Color _getStatusBackgroundColor() {
    if (connectionStatus.contains("Lỗi")) return Colors.red[100]!;
    if (connectionStatus.contains("thành công")) return Colors.green[100]!;
    return Colors.amber[100]!;
  }

  Color _getStatusBorderColor() {
    if (connectionStatus.contains("Lỗi")) return Colors.red;
    if (connectionStatus.contains("thành công")) return Colors.green;
    return Colors.amber;
  }

  @override
  Widget build(BuildContext context) {
    // The rest of your existing build method remains the same
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange[300]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left section with Logo and Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Image.asset('assets/FPTULogo.png', height: 36),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),

                    // Centered Title
                    const Expanded(
                      child: Center(
                        child: Text(
                          'AlphaMini FSTEM',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ),
                    ),

                    // Refresh Button
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.refresh,
                          color: Colors.deepOrange,
                        ),
                      ),
                      onPressed: _reloadConnection,
                    ),
                  ],
                ),
              ),

              // Connection Status Indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: _getStatusBackgroundColor(),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getStatusBorderColor(),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      connectionStatus.contains("Lỗi")
                          ? Icons.error_outline
                          : connectionStatus.contains("thành công")
                          ? Icons.check_circle_outline
                          : Icons.hourglass_empty,
                      color: _getStatusBorderColor(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        connectionStatus,
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              connectionStatus.contains("Lỗi")
                                  ? Colors.red[800]
                                  : connectionStatus.contains("thành công")
                                  ? Colors.green[800]
                                  : Colors.amber[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Feature Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildFeatureCard(
                        title: 'Hành động',
                        icon: Icons.directions_run,
                        color: Colors.orange,
                        onTap: () => _goToActionScreen(context),
                      ),
                      _buildFeatureCard(
                        title: 'Nhảy',
                        icon: Icons.music_note,
                        color: Colors.pink,
                        onTap: () => _goToDanceScreen(context),
                      ),
                      _buildFeatureCard(
                        title: 'Điều khiển',
                        icon: Icons.gamepad,
                        color: Colors.blue,
                        onTap: () => _goToControllerScreen(context),
                      ),
                      _buildFeatureCard(
                        title: 'Biểu cảm',
                        icon: Icons.face,
                        color: Colors.purple,
                        onTap: () => _goToExpressionScreen(context),
                      ),
                      // _buildFeatureCard(
                      //   title: 'Bluetooth',
                      //   icon: Icons.bluetooth,
                      //   color: Colors.green,
                      //   onTap: () => _goToBluetoothScreen(context),
                      // ),
                      _buildFeatureCard(
                        title: 'Giọng nói',
                        icon: Icons.mic,
                        color: Colors.red,
                        onTap: () => _goToSpeechToTextScreen(context),
                      ),
                      _buildFeatureCard(
                        title: 'Thư viện ảnh',
                        icon: Icons.image,
                        color: Colors.amber,
                        onTap: () => _goToImageGallery(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedFeatureCard(
      title: title,
      icon: icon,
      color: color,
      onTap: onTap,
    );
  }
}

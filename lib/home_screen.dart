import 'package:flutter/material.dart';
import 'package:flutterdemo0/bluetooth_screen.dart';
import 'package:flutterdemo0/speech_to_text_screen.dart';
import 'action_screen.dart';
import 'animated_feature_card.dart';
import 'button_control_screen.dart';
import 'face_control_screen.dart';
import 'motor_screen.dart';
import 'testcamera_screen.dart';
import 'dance_screen.dart';
import 'controller_screen.dart';
import 'expression_screen.dart';
import 'WebSocketService.dart';
// ignore: unnecessary_import
import 'package:flutter/services.dart';

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
  String connectionStatus = "Waiting for WebSocket connection...";

  @override
  void initState() {
    super.initState();
    widget.webSocketService.messageStream.listen(
      (message) {
        setState(() {
          connectionStatus = "WebSocket connected successfully!";
        });
      },
      onError: (error) {
        setState(() {
          connectionStatus = "WebSocket connection error: $error";
        });
      },
    );
  }

  void _reloadConnection() {
    setState(() {
      connectionStatus = "Reconnecting to WebSocket...";
    });
    widget.webSocketService.connect('ws://192.168.1.83:8001/ws');
  }

  void _goToActionScreen(BuildContext context) {
    Navigator.push(
      context,
      CustomPageRoute(
        page: ActionScreen(webSocketService: widget.webSocketService),
      ),
    );
  }

  void _goToMotorScreen(BuildContext context) {
    Navigator.push(
      context,
      CustomPageRoute(
        page: MotorScreen(webSocketService: widget.webSocketService),
      ),
    );
  }

  void _goToTestCameraScreen(BuildContext context) {
    Navigator.push(context, CustomPageRoute(page: TestCameraScreen()));
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
    Navigator.push(
      context,
      CustomPageRoute(
        page: ControllerScreen(webSocketService: widget.webSocketService),
      ),
    );
  }

  void _goToExpressionScreen(BuildContext context) {
    Navigator.push(
      context,
      CustomPageRoute(
        page: ExpressionScreen(webSocketService: widget.webSocketService),
      ),
    );
  }

  void _goToBluetoothScreen(BuildContext context) {
    widget.webSocketService.sendMessage("Book");
    Navigator.push(
      context,
      CustomPageRoute(
        page: BluetoothConnectionPage(
          webSocketService: widget.webSocketService,
        ),
      ),
    );
  }

  void _goToButtonControlScreen(BuildContext context) {
    widget.webSocketService.sendMessage("Book");
    Navigator.push(
      context,
      CustomPageRoute(
        page: ButtonControlScreen(webSocketService: widget.webSocketService),
      ),
    );
  }

  void _goToFaceControlScreen(BuildContext context) {
    widget.webSocketService.sendMessage("Face");
    Navigator.push(
      context,
      CustomPageRoute(
        page: FaceControlScreen(webSocketService: widget.webSocketService),
      ),
    );
  }

  void _goToSpeechToTextScreen(BuildContext context) {
    widget.webSocketService.sendMessage("Face");
    Navigator.push(
      context,
      CustomPageRoute(
        page: SpeechToTextScreen(webSocketService: widget.webSocketService),
      ),
    );
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
                          'Alpha Mini Robot Control',
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
                  color:
                      connectionStatus.contains("error")
                          ? Colors.red[100]
                          : connectionStatus.contains("connected")
                          ? Colors.green[100]
                          : Colors.amber[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        connectionStatus.contains("error")
                            ? Colors.red
                            : connectionStatus.contains("connected")
                            ? Colors.green
                            : Colors.amber,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      connectionStatus.contains("error")
                          ? Icons.error_outline
                          : connectionStatus.contains("connected")
                          ? Icons.check_circle_outline
                          : Icons.hourglass_empty,
                      color:
                          connectionStatus.contains("error")
                              ? Colors.red
                              : connectionStatus.contains("connected")
                              ? Colors.green
                              : Colors.amber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        connectionStatus,
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              connectionStatus.contains("error")
                                  ? Colors.red[800]
                                  : connectionStatus.contains("connected")
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
                        title: 'Action',
                        icon: Icons.directions_run,
                        color: Colors.orange,
                        onTap: () => _goToActionScreen(context),
                      ),
                      _buildFeatureCard(
                        title: 'Dance',
                        icon: Icons.music_note,
                        color: Colors.pink,
                        onTap: () => _goToDanceScreen(context),
                      ),
                      _buildFeatureCard(
                        title: 'Controller',
                        icon: Icons.gamepad,
                        color: Colors.blue,
                        onTap: () => _goToControllerScreen(context),
                      ),
                      _buildFeatureCard(
                        title: 'Expression',
                        icon: Icons.face,
                        color: Colors.purple,
                        onTap: () => _goToExpressionScreen(context),
                      ),
                      _buildFeatureCard(
                        title: 'Motor',
                        icon: Icons.settings,
                        color: Colors.teal,
                        onTap: () => _goToMotorScreen(context),
                      ),
                      _buildFeatureCard(
                        title: 'Bluetooth',
                        icon: Icons.bluetooth,
                        color: Colors.green,
                        onTap: () => _goToBluetoothScreen(context),
                      ),
                      _buildFeatureCard(
                        title: 'Test Camera',
                        icon: Icons.photo_camera,
                        color: Colors.indigo,
                        onTap: () => _goToTestCameraScreen(context),
                      ),
                      _buildFeatureCard(
                        title: 'Voice',
                        icon: Icons.mic,
                        color: Colors.red,
                        onTap: () => _goToSpeechToTextScreen(context),
                      ),
                      _buildFeatureCard(
                        title: 'Button Control',
                        icon: Icons.swipe_down_alt,
                        color: Colors.orange,
                        onTap: () => _goToButtonControlScreen(context),
                      ),
                      _buildFeatureCard(
                        title: 'Face Control',
                        icon: Icons.face,
                        color: Colors.pink,
                        onTap: () => _goToFaceControlScreen(context),
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

  // Helper method to get an appropriate text color
  Color _getTextColor(Color baseColor) {
    if (baseColor == Colors.orange) return Colors.orange[800] ?? Colors.orange;
    if (baseColor == Colors.pink) return Colors.pink[800] ?? Colors.pink;
    if (baseColor == Colors.blue) return Colors.blue[800] ?? Colors.blue;
    if (baseColor == Colors.purple) return Colors.purple[800] ?? Colors.purple;
    if (baseColor == const Color.fromARGB(255, 30, 195, 179)) {
      return Colors.teal[800] ?? Colors.teal;
    }
    if (baseColor == Colors.green) return Colors.green[800] ?? Colors.green;
    if (baseColor == Colors.indigo) return Colors.indigo[800] ?? Colors.indigo;
    if (baseColor == Colors.red) return Colors.red[800] ?? Colors.red;
    return Colors.black;
  }
}

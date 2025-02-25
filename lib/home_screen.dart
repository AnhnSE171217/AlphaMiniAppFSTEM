import 'package:flutter/material.dart';
import 'action_screen.dart';
import 'motor_screen.dart';
import 'bluetooth_screen.dart';
import 'testcamera_screen.dart';
import 'voice_screen.dart'; // Import VoiceScreen
import 'dance_screen.dart'; // Import DanceScreen
import 'controller_screen.dart'; // Import ControllerScreen
import 'expression_screen.dart'; // Import ExpressionScreen
import 'WebSocketService.dart';

class HomeScreen extends StatefulWidget {
  final WebSocketService webSocketService;

  const HomeScreen({Key? key, required this.webSocketService}) : super(key: key);

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
      MaterialPageRoute(builder: (context) => ActionScreen(webSocketService: widget.webSocketService)),
    );
  }

  void _goToMotorScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MotorScreen(webSocketService: widget.webSocketService)),
    );
  }

  void _goToBluetoothScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BluetoothScreen()),
    );
  }

  void _goToTestCameraScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TestCameraScreen()),
    );
  }

  void _goToVoiceScreen(BuildContext context) {
    widget.webSocketService.sendMessage("Voice"); // Gửi Voice đến WebSocket
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoiceScreen(webSocketService: widget.webSocketService),
      ),
    );
  }

  void _goToDanceScreen(BuildContext context) {
    widget.webSocketService.sendMessage("Dance"); // Gửi Dance đến WebSocket
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DanceScreen(webSocketService: widget.webSocketService)),
    );
  }

  void _goToControllerScreen(BuildContext context) {
    widget.webSocketService.sendMessage("Controller"); // Gửi Controller đến WebSocket
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ControllerScreen(webSocketService: widget.webSocketService)),
    );
  }

  void _goToExpressionScreen(BuildContext context) {
    /*widget.webSocketService.sendMessage("Expression");*/ // Gửi Expression đến WebSocket
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ExpressionScreen(webSocketService: widget.webSocketService)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/FPTULogo.png',
              height: 40,
            ),
            const SizedBox(width: 10),
            const Text('Home Screen'),
          ],
        ),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _reloadConnection,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _goToActionScreen(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Action', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Nút mới "Dance"
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _goToDanceScreen(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Dance', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Nút mới "Controller"
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _goToControllerScreen(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Controller', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Nút mới "Expression"
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _goToExpressionScreen(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Expression', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _goToMotorScreen(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Motor', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _goToBluetoothScreen(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Bluetooth', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _goToTestCameraScreen(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Test Camera', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _goToVoiceScreen(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Voice', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // Footer thông báo kết nối WebSocket
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: connectionStatus.contains("error") ? Colors.red : Colors.green,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              connectionStatus,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
    );
  }
}

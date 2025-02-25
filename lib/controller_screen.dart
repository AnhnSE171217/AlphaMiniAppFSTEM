import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'WebSocketService.dart';

class ControllerScreen extends StatefulWidget {
  final WebSocketService webSocketService;

  const ControllerScreen({Key? key, required this.webSocketService}) : super(key: key);

  @override
  _ControllerScreenState createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  final Logger logger = Logger();
  String connectionStatus = "Connecting to WebSocket...";
  Timer? _timer;
  Map<String, bool> _buttonStates = {
    "Up": false,
    "Down": false,
    "Left": false,
    "Right": false,
  };

  @override
  void initState() {
    super.initState();
    widget.webSocketService.sendMessage("Controller");

    widget.webSocketService.messageStream.listen(
          (message) {
        logger.i("Received message: $message");
      },
      onError: (error) {
        setState(() {
          connectionStatus = "WebSocket connection error: $error";
        });
      },
      onDone: () {
        setState(() {
          connectionStatus = "WebSocket connection closed.";
        });
      },
    );

    setState(() {
      connectionStatus = "WebSocket connected successfully!";
    });
  }

  @override
  void dispose() {
    widget.webSocketService.sendMessage("Close");
    super.dispose();
  }

  void _sendMessage(String direction) {
    widget.webSocketService.sendMessage(direction);
  }

  void _onLongPressStart(LongPressStartDetails details, String direction) {
    setState(() {
      _buttonStates[direction] = true;
    });
    _sendMessage(direction);

    _timer = Timer.periodic(Duration(milliseconds: 2000), (timer) {
      if (_buttonStates.containsValue(true)) {
        _sendMessage(direction);
      }
    });
  }

  void _onLongPressEnd(LongPressEndDetails details, String direction) {
    setState(() {
      _buttonStates[direction] = false;
    });
    _timer?.cancel();
  }

  void _onSingleClick(String direction) {
    _sendMessage(direction);
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text("Controller"),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            widget.webSocketService.sendMessage("Close");
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: screenHeight * 0.45,
            color: Colors.black,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Text(
              connectionStatus,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTriangleButton("Up", 0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTriangleButton("Left", -90),
                      SizedBox(width: 40),
                      _buildTriangleButton("Right", 90),
                    ],
                  ),
                  _buildTriangleButton("Down", 180),
                ],
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildTriangleButton(String direction, double angle) {
    return GestureDetector(
      onLongPressStart: (details) => _onLongPressStart(details, direction),
      onLongPressEnd: (details) => _onLongPressEnd(details, direction),
      onTap: () => _onSingleClick(direction),
      child: Transform.rotate(
        angle: angle * 3.1415926535 / 180,
        child: ClipPath(
          clipper: TriangleClipper(),
          child: Container(
            width: 80,
            height: 80,
            color: Colors.blueAccent,
          ),
        ),
      ),
    );
  }
}

class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(TriangleClipper oldClipper) => false;
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'WebSocketService.dart';

class MotorScreen extends StatefulWidget {
  final WebSocketService webSocketService;

  const MotorScreen({Key? key, required this.webSocketService}) : super(key: key);

  @override
  _MotorScreenState createState() => _MotorScreenState();
}

class _MotorScreenState extends State<MotorScreen> {
  final Logger logger = Logger();
  String connectionStatus = "Connecting to WebSocket...";

  @override
  void initState() {
    super.initState();

    // Gửi thông điệp "Motor" khi mở trang
    widget.webSocketService.sendMessage("Dance");

    // Lắng nghe stream từ WebSocketService
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
    super.dispose();
  }

  String _getRandomCatImage() {
    int randomIndex = Random().nextInt(4) + 1;
    return "assets/cat$randomIndex.png";
  }

  // Thêm hành động gửi "Close" và quay lại trang Home
  void _goBack() {
    widget.webSocketService.sendMessage("Close");  // Gửi thông điệp "Close"
    Navigator.pop(context);  // Quay lại trang HomeScreen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(connectionStatus),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back), // Mũi tên thẳng
          onPressed: _goBack,  // Gọi phương thức _goBack
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.4,
            color: Colors.black,
            alignment: Alignment.center,
            child: Text(
              connectionStatus,
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 16,
                itemBuilder: (context, index) {
                  int buttonNumber = index + 1;
                  return GestureDetector(
                    onTap: () => widget.webSocketService.sendMessage(buttonNumber.toString()),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child: Image.asset(
                              _getRandomCatImage(),
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Button $buttonNumber',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
    );
  }
}

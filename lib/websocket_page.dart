import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';  // Import logger

class WebSocketPage extends StatefulWidget {
  const WebSocketPage({super.key});

  @override
  State<WebSocketPage> createState() => WebSocketPageState(); // Using WebSocketPageState

  // Method to access sendMessage from outside the widget
  static WebSocketPageState? of(BuildContext context) {
    return context.findAncestorStateOfType<WebSocketPageState>(); // Access the state of WebSocketPage
  }
}

class WebSocketPageState extends State<WebSocketPage> {
  // Make channel public instead of private
  final WebSocketChannel channel = WebSocketChannel.connect(
    Uri.parse('ws://192.168.1.83:8001/ws'),  // Ensure you use the correct WebSocket URL
  );

  // Initialize Logger
  final Logger logger = Logger();

  @override
  void initState() {
    super.initState();
    // Log when WebSocket connection is successful
    logger.i("WebSocket Connected!");
  }

  // Function to send a message to WebSocket
  void sendMessage(String message) {
    if (channel != null && channel.sink != null) {
      logger.i("Sending message: $message");
      channel.sink.add(message); // Gửi tin nhắn nếu kết nối hợp lệ
    } else {
      logger.e("Kết nối WebSocket chưa được thiết lập. Không thể gửi tin nhắn.");
    }
  }

  @override
  void dispose() {
    channel.sink.close();  // Đóng kết nối WebSocket khi widget bị hủy
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // StreamBuilder to listen for incoming WebSocket data
        StreamBuilder(
          stream: channel.stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              logger.e("Error: ${snapshot.error}");
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasData) {
              // Log received data
              logger.i('Received message: ${snapshot.data}');
              return Text('Received: ${snapshot.data}');
            } else {
              return const Text('Waiting for message...');
            }
          },
        )
      ],
    );
  }
}

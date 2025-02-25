import 'dart:math';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'WebSocketService.dart';

class ExpressionScreen extends StatefulWidget {
  final WebSocketService webSocketService;

  const ExpressionScreen({Key? key, required this.webSocketService}) : super(key: key);

  @override
  _ExpressionScreenState createState() => _ExpressionScreenState();
}

class _ExpressionScreenState extends State<ExpressionScreen> {
  final Logger logger = Logger();
  String connectionStatus = "Connecting to WebSocket...";

  @override
  void initState() {
    super.initState();
    widget.webSocketService.sendMessage("Expression");

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

  void _goBack() {
    widget.webSocketService.sendMessage("Close");
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Lấy kích thước màn hình
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text("Expression"),
        backgroundColor: Colors.orange,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
      ),
      body: Column(
        children: [
          // Container chứa trạng thái kết nối WebSocket với chiều cao linh hoạt
          Container(
            width: double.infinity,
            height: screenHeight * 0.45, // Tăng chiều cao của container chứa trạng thái kết nối lên 30%
            color: Colors.black,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05), // Padding linh động
            child: Text(
              connectionStatus,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.0, // Điều chỉnh childAspectRatio để tạo không gian cho text
                ),
                itemCount: 87,
                itemBuilder: (context, index) {
                  int buttonNumber = index + 1;
                  return GestureDetector(
                    onTap: () => widget.webSocketService.sendMessage(buttonNumber.toString()),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: screenWidth * 0.08, // Giảm kích thước CircleAvatar để tránh overflow
                          backgroundColor: Colors.orangeAccent,
                          child: ClipOval(
                            child: Image.asset(
                              _getRandomCatImage(),
                              width: screenWidth * 0.12, // Điều chỉnh kích thước ảnh trong CircleAvatar
                              height: screenWidth * 0.12,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Thêm Flexible và điều chỉnh chiều rộng của phần Text
                        Flexible(
                          child: Container(
                            width: screenWidth * 0.18, // Giới hạn chiều rộng của text
                            alignment: Alignment.center,
                            child: Text(
                              'Button ' + buttonNumber.toString(),
                              style: TextStyle(
                                fontSize: screenWidth * 0.04, // Điều chỉnh font size linh động
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis, // Tránh chữ bị cắt ngang
                              textAlign: TextAlign.center,
                            ),
                          ),
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

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'WebSocketService.dart';

class DanceScreen extends StatefulWidget {
  final WebSocketService webSocketService;

  const DanceScreen({Key? key, required this.webSocketService}) : super(key: key);

  @override
  _DanceScreenState createState() => _DanceScreenState();
}

class _DanceScreenState extends State<DanceScreen> {
  final Logger logger = Logger();
  String connectionStatus = "Connecting to WebSocket...";

  @override
  void initState() {
    super.initState();
    widget.webSocketService.sendMessage("Dance");

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

  String _getRandomDanceImage() {
    int randomIndex = Random().nextInt(4) + 1;
    return "assets/cat$randomIndex.png";
  }

  void _goBack() {
    widget.webSocketService.sendMessage("Close");
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text("Dance"),
        backgroundColor: Colors.pink,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _goBack,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.0,
                ),
                itemCount: 50,
                itemBuilder: (context, index) {
                  int buttonNumber = index + 1;
                  return GestureDetector(
                    onTap: () => widget.webSocketService.sendMessage(buttonNumber.toString()),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: screenWidth * 0.08,
                          backgroundColor: Colors.pinkAccent,
                          child: ClipOval(
                            child: Image.asset(
                              _getRandomDanceImage(),
                              width: screenWidth * 0.12,
                              height: screenWidth * 0.12,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Flexible(
                          child: Container(
                            width: screenWidth * 0.18,
                            alignment: Alignment.center,
                            child: Text(
                              'Dance Button ' + buttonNumber.toString(),
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
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

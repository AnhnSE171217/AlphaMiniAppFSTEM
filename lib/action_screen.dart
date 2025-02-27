import 'dart:math';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'WebSocketService.dart';

class ActionScreen extends StatefulWidget {
  final WebSocketService webSocketService;

  const ActionScreen({super.key, required this.webSocketService});

  @override
  _ActionScreenState createState() => _ActionScreenState();
}

class _ActionScreenState extends State<ActionScreen>
    with SingleTickerProviderStateMixin {
  final Logger logger = Logger();
  String connectionStatus = "Connecting to WebSocket...";
  int? selectedButtonIndex;
  late AnimationController _animationController;

  final List<Color> gradientColors = [
    Color(0xFFFF9800), // Orange
    Color(0xFFFFB74D), // Light orange
    Color(0xFFFF7043), // Deep orange
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    widget.webSocketService.sendMessage("Action");

    widget.webSocketService.messageStream.listen(
      (message) {
        logger.i("Received message: $message");
      },
      onError: (error) {
        setState(() {
          connectionStatus = "Connection error: $error";
        });
      },
      onDone: () {
        setState(() {
          connectionStatus = "Connection closed";
        });
      },
    );

    setState(() {
      connectionStatus = "Connected successfully!";
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    widget.webSocketService.sendMessage("Close");
    super.dispose();
  }

  String _getCatImage(int index) {
    // Use deterministic pattern based on index
    return "assets/cat${(index % 4) + 1}.png";
  }

  void _sendAction(int buttonNumber) {
    widget.webSocketService.sendMessage(buttonNumber.toString());
    setState(() {
      selectedButtonIndex = buttonNumber - 1;
    });

    _animationController.reset();
    _animationController.forward();

    logger.i("Sent action: $buttonNumber");
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Actions",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _goBack,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Connection Status Card
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                height: screenHeight * 0.2,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi, color: Colors.orange.shade300, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      connectionStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Buttons Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: 87,
                    itemBuilder: (context, index) {
                      int buttonNumber = index + 1;
                      bool isSelected = selectedButtonIndex == index;

                      return AnimatedScale(
                        scale: isSelected ? 0.9 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: GestureDetector(
                          onTap: () => _sendAction(buttonNumber),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      isSelected
                                          ? Colors.orange.withOpacity(0.5)
                                          : Colors.black.withOpacity(0.1),
                                  blurRadius: isSelected ? 12 : 6,
                                  spreadRadius: isSelected ? 2 : 0,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border:
                                  isSelected
                                      ? Border.all(
                                        color: Colors.orange.shade300,
                                        width: 2,
                                      )
                                      : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.orange.shade300,
                                        Colors.orange.shade600,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.4),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: screenWidth * 0.06,
                                    backgroundColor: Colors.white,
                                    child: ClipOval(
                                      child: Image.asset(
                                        _getCatImage(index),
                                        width: screenWidth * 0.1,
                                        height: screenWidth * 0.1,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    width: double.infinity,
                                    child: Text(
                                      'Button $buttonNumber',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.028,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade800,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

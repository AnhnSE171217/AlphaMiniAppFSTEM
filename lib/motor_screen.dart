import 'dart:math';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'WebSocketService.dart';

class MotorScreen extends StatefulWidget {
  final WebSocketService webSocketService;

  const MotorScreen({super.key, required this.webSocketService});

  @override
  _MotorScreenState createState() => _MotorScreenState();
}

class _MotorScreenState extends State<MotorScreen>
    with SingleTickerProviderStateMixin {
  final Logger logger = Logger();
  String connectionStatus = "Select a button to control motor!";
  late AnimationController _animationController;
  int? selectedButtonIndex;

  final List<Color> gradientColors = [
    Color(0xFF2196F3), // Blue primary
    Color(0xFF64B5F6), // Light blue
    Color(0xFF1976D2), // Dark blue
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Send "Dance" message when opening the page
    widget.webSocketService.sendMessage("Dance");

    // Listen to WebSocketService stream
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
      connectionStatus = "Select a button to control motor!";
    });
  }

  @override
  void dispose() {
    widget.webSocketService.sendMessage("Close");
    _animationController.dispose();
    super.dispose();
  }

  String _getMotorImage(int index) {
    // Use a deterministic pattern based on the index to make images consistent
    return "assets/cat${(index % 4) + 1}.png";
  }

  void _performMotorControl(int buttonNumber) {
    String message = "Button #$buttonNumber activated!";
    widget.webSocketService.sendMessage(buttonNumber.toString());

    setState(() {
      connectionStatus = message;
      selectedButtonIndex = buttonNumber - 1;
    });

    _animationController.reset();
    _animationController.forward();

    logger.i(message);
  }

  // Back button action
  void _goBack() {
    widget.webSocketService.sendMessage("Close");
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Motor Controls",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(76), // Replaced withOpacity(0.3)
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
              // Status Card
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(
                        31,
                      ), // Replaced withOpacity(0.12)
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.blue.shade400, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        connectionStatus,
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Control Buttons Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: 16,
                    itemBuilder: (context, index) {
                      int buttonNumber = index + 1;
                      bool isSelected = selectedButtonIndex == index;

                      return AnimatedScale(
                        scale: isSelected ? 0.9 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: GestureDetector(
                          onTap: () => _performMotorControl(buttonNumber),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      isSelected
                                          ? Colors.blue.withAlpha(
                                            128,
                                          ) // Replaced withOpacity(0.5)
                                          : Colors.black.withAlpha(
                                            26,
                                          ), // Replaced withOpacity(0.1)
                                  blurRadius: isSelected ? 12 : 6,
                                  spreadRadius: isSelected ? 2 : 0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border:
                                  isSelected
                                      ? Border.all(
                                        color: Colors.blue.shade300,
                                        width: 3,
                                      )
                                      : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Hero(
                                  tag: "motorButton$buttonNumber",
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue.shade300,
                                          Colors.blue.shade600,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withAlpha(
                                            102,
                                          ), // Replaced withOpacity(0.4)
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: screenWidth * 0.07,
                                      backgroundColor: Colors.white,
                                      child: ClipOval(
                                        child: Image.asset(
                                          _getMotorImage(index),
                                          width: screenWidth * 0.13,
                                          height: screenWidth * 0.13,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Button $buttonNumber",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.033,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                  textAlign: TextAlign.center,
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

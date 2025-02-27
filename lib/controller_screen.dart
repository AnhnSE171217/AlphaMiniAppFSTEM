import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'WebSocketService.dart';

class ControllerScreen extends StatefulWidget {
  final WebSocketService webSocketService;

  const ControllerScreen({super.key, required this.webSocketService});

  @override
  _ControllerScreenState createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen>
    with SingleTickerProviderStateMixin {
  final Logger logger = Logger();
  String connectionStatus = "Connected to Robot";
  String lastAction = "Ready";
  Timer? _timer;
  final Map<String, bool> _buttonStates = {
    "Up": false,
    "Down": false,
    "Left": false,
    "Right": false,
    "StandUp": false,
    "SitDown": false,
    "squat": false,
  };

  // Map display names to actual commands sent
  final Map<String, String> _actionCommands = {
    "Stand Up": "StandUp",
    "Sit Down": "SitDown",
    "Squat": "squat", // Display name is capitalized, but command is lowercase
  };

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    widget.webSocketService.sendMessage("Controller");

    // Setup pulse animation for connection indicator
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    widget.webSocketService.messageStream.listen(
      (message) {
        logger.i("Received message: $message");
        setState(() {
          lastAction = "Command: $message received";
        });
      },
      onError: (error) {
        setState(() {
          connectionStatus = "Connection Error";
          lastAction = error.toString();
        });
      },
      onDone: () {
        setState(() {
          connectionStatus = "Disconnected";
          lastAction = "Connection closed";
        });
      },
    );

    setState(() {
      connectionStatus = "Connected to Robot";
    });
  }

  @override
  void dispose() {
    widget.webSocketService.sendMessage("Close");
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _sendMessage(String command) {
    widget.webSocketService.sendMessage(command);
    setState(() {
      lastAction = "Moving: $command";
    });
    HapticFeedback.mediumImpact();
  }

  void _onLongPressStart(String direction) {
    setState(() {
      _buttonStates[direction] = true;
    });
    _sendMessage(direction);

    // Continue sending while pressed
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _sendMessage(direction);
    });
  }

  void _onLongPressEnd(String direction) {
    setState(() {
      _buttonStates[direction] = false;
      lastAction = "Stopped: $direction";
    });
    _timer?.cancel();
  }

  void _onSingleTap(String direction) {
    _sendMessage(direction);
    Future.delayed(const Duration(milliseconds: 200), () {});
  }

  void _onActionButtonPress(String displayName) {
    // Get the actual command to send
    final command = _actionCommands[displayName] ?? displayName;

    setState(() {
      // Set all action button states to false
      _buttonStates["StandUp"] = false;
      _buttonStates["SitDown"] = false;
      _buttonStates["squat"] = false;

      // Set the pressed button state to true
      _buttonStates[command] = true;
    });

    // Send the command (not the display name)
    _sendMessage(command);

    // Reset the button state after a short delay for visual feedback
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _buttonStates[command] = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(77), // 0.3 * 255 ≈ 77
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              widget.webSocketService.sendMessage("Close");
              Navigator.pop(context);
            },
          ),
        ),
        title: const Text(
          "Robot Controller",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade800,
              Colors.blue.shade500,
              Colors.indigo.shade800,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Status Card
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildStatusCard(),
              ),

              // Controller Pad
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(38), // 0.15 * 255 ≈ 38
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _buildControllerPad(),
                  ),
                ),
              ),

              // Action Buttons Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildActionButtonsBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38), // 0.15 * 255 ≈ 38
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withAlpha(51), // 0.2 * 255 ≈ 51
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Connection status indicator
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      connectionStatus.contains("Error")
                          ? Colors.red
                          : Colors.green,
                  boxShadow: [
                    BoxShadow(
                      color: (connectionStatus.contains("Error")
                              ? Colors.red
                              : Colors.green)
                          .withAlpha(
                            (_pulseAnimation.value * 0.7 * 255).toInt(),
                          ), // converting opacity to alpha
                      blurRadius: 10 * _pulseAnimation.value,
                      spreadRadius: 2 * _pulseAnimation.value,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connectionStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lastAction,
                  style: TextStyle(
                    color: Colors.white.withAlpha(179), // 0.7 * 255 ≈ 179
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControllerPad() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDirectionButton("Up", Icons.arrow_upward),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDirectionButton("Left", Icons.arrow_back),
            const SizedBox(width: 12),
            _buildCenterButton(),
            const SizedBox(width: 12),
            _buildDirectionButton("Right", Icons.arrow_forward),
          ],
        ),
        const SizedBox(height: 12),
        _buildDirectionButton("Down", Icons.arrow_downward),
      ],
    );
  }

  Widget _buildActionButtonsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38), // 0.15 * 255 ≈ 38
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withAlpha(51), // 0.2 * 255 ≈ 51
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton("Stand Up", Icons.accessibility_new),
          _buildActionButton("Sit Down", Icons.chair),
          _buildActionButton("Squat", Icons.fitness_center),
        ],
      ),
    );
  }

  Widget _buildActionButton(String displayName, IconData icon) {
    final command = _actionCommands[displayName] ?? displayName;
    final isPressed = _buttonStates[command] ?? false;

    return GestureDetector(
      onTap: () => _onActionButtonPress(displayName),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 100,
        height: 70,
        decoration: BoxDecoration(
          color:
              isPressed
                  ? Colors.white.withAlpha(77)
                  : Colors.white.withAlpha(26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isPressed
                    ? Colors.white.withAlpha(204)
                    : Colors.white.withAlpha(77),
            width: 2,
          ),
          boxShadow:
              isPressed
                  ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.black.withAlpha(51),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
        ),
        transform: Matrix4.identity()..translate(0.0, isPressed ? 2.0 : 0.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionButton(String direction, IconData icon) {
    final isPressed = _buttonStates[direction] ?? false;

    return GestureDetector(
      onTapDown: (_) => _onLongPressStart(direction),
      onTapUp: (_) => _onLongPressEnd(direction),
      onTapCancel: () => _onLongPressEnd(direction),
      onTap: () => _onSingleTap(direction),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color:
              isPressed
                  ? Colors.white.withAlpha(77)
                  : Colors.white.withAlpha(26), // 0.3 and 0.1 * 255
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isPressed
                    ? Colors.white.withAlpha(204)
                    : Colors.white.withAlpha(77), // 0.8 and 0.3 * 255
            width: 2,
          ),
          boxShadow:
              isPressed
                  ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(26), // 0.1 * 255 ≈ 26
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.black.withAlpha(51), // 0.2 * 255 ≈ 51
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
        ),
        transform: Matrix4.identity()..translate(0.0, isPressed ? 2.0 : 0.0),
        child: Icon(icon, color: Colors.white, size: 36),
      ),
    );
  }

  Widget _buildCenterButton() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13), // 0.05 * 255 ≈ 13
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withAlpha(26), // 0.1 * 255 ≈ 26
          width: 2,
        ),
      ),
      child: const Icon(Icons.stop, color: Colors.white54, size: 36),
    );
  }
}

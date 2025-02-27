import 'package:flutter/material.dart';
import 'WebSocketService.dart';

class ButtonControlScreen extends StatefulWidget {
  final WebSocketService webSocketService;

  const ButtonControlScreen({super.key, required this.webSocketService});

  @override
  State<ButtonControlScreen> createState() => _ButtonControlScreenState();
}

class _ButtonControlScreenState extends State<ButtonControlScreen> {
  String lastCommand = "No command sent yet";
  bool isProcessing = false;

  void _sendCommand(String command) {
    setState(() {
      isProcessing = true;
      lastCommand = "Sending: $command";
    });

    // Send the command through WebSocket
    widget.webSocketService.sendMessage(command);

    // Simulate a response delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          isProcessing = false;
          lastCommand = "Sent: $command";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Button Controls',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepOrange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepOrange.shade300, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Status panel
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isProcessing 
                            ? Colors.amber.shade100 
                            : Colors.green.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isProcessing 
                            ? Icons.autorenew 
                            : Icons.check_circle,
                        color: isProcessing 
                            ? Colors.amber 
                            : Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isProcessing 
                                ? "Processing..." 
                                : "Ready to send commands",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lastCommand,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Buttons
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Button 1
                      _buildCommandButton(
                        label: "Command 1",
                        command: "StartBook",
                        color: Colors.blue,
                        icon: Icons.filter_1,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Button 2
                      _buildCommandButton(
                        label: "Command 2",
                        command: "EndBook",
                        color: Colors.purple,
                        icon: Icons.filter_2,
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

  Widget _buildCommandButton({
    required String label,
    required String command,
    required Color color,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: isProcessing ? null : () => _sendCommand(command),
      child: AnimatedOpacity(
        opacity: isProcessing ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.8),
                color,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
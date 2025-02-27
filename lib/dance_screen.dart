import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'WebSocketService.dart';

class DanceScreen extends StatefulWidget {
  final WebSocketService webSocketService;

  const DanceScreen({super.key, required this.webSocketService});

  @override
  _DanceScreenState createState() => _DanceScreenState();
}

class _DanceScreenState extends State<DanceScreen>
    with SingleTickerProviderStateMixin {
  final Logger logger = Logger();
  String danceStatus = "Select a move to start dancing!";
  late AnimationController _animationController;
  int? selectedMoveIndex;

  final List<Color> gradientColors = [
    Color(0xFFFF4081), // Pink accent
    Color(0xFFFF80AB), // Light pink
    Color(0xFFF50057), // Deep pink
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    widget.webSocketService.sendMessage("Close");
    _animationController.dispose();
    super.dispose();
  }

  void _performDanceMove(int moveNumber) {
    String message = "Move #$moveNumber activated!";
    widget.webSocketService.sendMessage(moveNumber.toString());

    setState(() {
      danceStatus = message;
      selectedMoveIndex = moveNumber - 1;
    });

    _animationController.reset();
    _animationController.forward();

    logger.i(message);
  }

  String _getDanceImage(int index) {
    // Use a deterministic pattern based on the index to make images consistent
    return "assets/cat${(index % 4) + 1}.png";
  }

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
          "Dance Moves",
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
              // Dance Status Card
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
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.music_note,
                      color: Colors.pink.shade400,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        danceStatus,
                        style: TextStyle(
                          color: Colors.pink.shade800,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Dance Moves Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: 30,
                    itemBuilder: (context, index) {
                      int moveNumber = index + 1;
                      bool isSelected = selectedMoveIndex == index;

                      return AnimatedScale(
                        scale: isSelected ? 0.9 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: GestureDetector(
                          onTap: () => _performDanceMove(moveNumber),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      isSelected
                                          ? Colors.pink.withOpacity(0.5)
                                          : Colors.black.withOpacity(0.1),
                                  blurRadius: isSelected ? 12 : 6,
                                  spreadRadius: isSelected ? 2 : 0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border:
                                  isSelected
                                      ? Border.all(
                                        color: Colors.pink.shade300,
                                        width: 3,
                                      )
                                      : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Hero(
                                  tag: "danceMove$moveNumber",
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.pink.shade300,
                                          Colors.pink.shade600,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.pink.withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: screenWidth * 0.09,
                                      backgroundColor: Colors.white,
                                      child: ClipOval(
                                        child: Image.asset(
                                          _getDanceImage(index),
                                          width: screenWidth * 0.16,
                                          height: screenWidth * 0.16,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Move #$moveNumber",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.035,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.pink.shade800,
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

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'websocket_service.dart';

class ExpressionScreen extends StatefulWidget {
  final WebSocketService webSocketService;

  const ExpressionScreen({super.key, required this.webSocketService});

  @override
  State<ExpressionScreen> createState() => _ExpressionScreenState();
}

class _ExpressionScreenState extends State<ExpressionScreen>
    with SingleTickerProviderStateMixin {
  final Logger logger = Logger();
  String connectionStatus = "Đang kết nối đến WebSocket...";
  int? selectedButtonIndex;
  late AnimationController _animationController;
  late final List<int> visibleExpressionIndexes;

  // Using a different color scheme for Expression screen
  final List<Color> gradientColors = [
    Color(0xFF9C27B0), // Purple
    Color(0xFFBA68C8), // Light purple
    Color(0xFF7B1FA2), // Deep purple
  ];

  // List of custom names for the buttons - updated to match server expressions
  final List<String> buttonNames = [
    "Lo âu", // emo_001
    "Hơi buồn ngủ", // emo_002
    "Thích", // emo_003
    "Sốc", // emo_004
    "Tức giận", // emo_005
    "Gian ác", // emo_006
    "Cười", // emo_007
    "Tsudere", // emo_008
    "Khóc", // emo_009
    "Ngại ngùng", // emo_010
    "Khóc to", // emo_011
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Calculate visible expressions (skipping empty ones)
    visibleExpressionIndexes = [];
    for (int i = 0; i < buttonNames.length; i++) {
      if (buttonNames[i].isNotEmpty) {
        visibleExpressionIndexes.add(i);
      }
    }

    widget.webSocketService.messageStream.listen(
      (message) {
        logger.i("Nhận tin nhắn: $message");
      },
      onError: (error) {
        setState(() {
          connectionStatus = "Lỗi kết nối: $error";
        });
      },
      onDone: () {
        setState(() {
          connectionStatus = "Kết nối đã đóng";
        });
      },
    );

    setState(() {
      connectionStatus = "Kết nối thành công!";
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getCatImage(int index) {
    // Use deterministic pattern based on index
    return "assets/cat${(index % 4) + 1}.png";
  }

  void _sendExpression(int buttonNumber) {
    widget.webSocketService.sendMessage(buttonNumber.toString());
    setState(() {
      selectedButtonIndex = buttonNumber - 1;
    });

    _animationController.reset();
    _animationController.forward();

    logger.i("Đã gửi biểu cảm: $buttonNumber");
  }

  void _goBack() {
    widget.webSocketService.sendMessage("Close");
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Remove unused screenHeight variable
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Biểu cảm", // Vietnamese title
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(76),
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
          bottom: true,
          child: Column(
            children: [
              // Connection Status Card
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.mood, color: Colors.purple.shade400, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          connectionStatus,
                          style: TextStyle(
                            color: Colors.purple.shade800,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Buttons Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          MediaQuery.of(context).size.width > 600 ? 5 : 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.95, // Adjusted for vertical space
                    ),
                    itemCount: visibleExpressionIndexes.length,
                    itemBuilder: (context, visibleIndex) {
                      int actualIndex = visibleExpressionIndexes[visibleIndex];
                      int buttonNumber =
                          actualIndex + 1; // Keep original numbering
                      bool isSelected = selectedButtonIndex == actualIndex;

                      return AnimatedScale(
                        scale: isSelected ? 0.9 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: GestureDetector(
                          onTap: () => _sendExpression(buttonNumber),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      isSelected
                                          ? Colors.purple.withAlpha(128)
                                          : Colors.black.withAlpha(26),
                                  blurRadius: isSelected ? 12 : 6,
                                  spreadRadius: isSelected ? 2 : 0,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border:
                                  isSelected
                                      ? Border.all(
                                        color: Colors.purple.shade300,
                                        width: 2,
                                      )
                                      : null,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Hero(
                                    tag: "expressionButton$buttonNumber",
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.purple.shade300,
                                            Colors.purple.shade600,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.purple.withAlpha(90),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: screenWidth * 0.05,
                                        backgroundColor: Colors.white,
                                        child: ClipOval(
                                          child: Image.asset(
                                            _getCatImage(actualIndex),
                                            width: screenWidth * 0.09,
                                            height: screenWidth * 0.09,
                                            fit: BoxFit.cover,
                                            cacheWidth:
                                                (screenWidth * 0.18).round(),
                                            cacheHeight:
                                                (screenWidth * 0.18).round(),
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Icon(
                                                Icons.mood,
                                                color: Colors.purple.shade300,
                                                size: screenWidth * 0.06,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Flexible(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      child: Text(
                                        buttonNames[actualIndex],
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.028,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple.shade800,
                                          height: 1.1,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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

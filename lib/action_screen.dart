import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'websocket_service.dart';

class ActionScreen extends StatefulWidget {
  final WebSocketService webSocketService;

  const ActionScreen({super.key, required this.webSocketService});

  @override
  State<ActionScreen> createState() => _ActionScreenState();
}

class _ActionScreenState extends State<ActionScreen>
    with SingleTickerProviderStateMixin {
  final Logger logger = Logger();
  String connectionStatus = "Đang kết nối đến WebSocket...";
  int? selectedButtonIndex;
  late AnimationController _animationController;
  late final List<int> visibleButtonIndexes;

  // Action names list remains unchanged
  final List<String> actionNames = [
    "Múa võ",
    "Ngã người đỡ chân trái",
    "Hít đất",
    "Ngồi",
    "", // Cook (skipped)
    "Ngã người đỡ chân phải",
    "Ngã người đỡ chân trái",
    "", // Cook (skipped)
    "Đỡ 2 tay lên và nhấc 2 chân",
    "Quỳ xuống",
    "Hắt xì",
    "Nát cục",
    "Đít",
    "Giận cỡ",
    "", // Hắt xì (cook)
    "Múa",
    "Múa 2",
    "Đỡ 1 chân phải lên trước",
    "Đỡ 1 chân trái lên trước",
    "", // Cook (skipped)
    "Đi lên",
    "Đi xuống",
    "", // Cook (skipped)
    "Chào buổi sáng",
    "Chào mừng trở lại",
    "Tôi thích bạn",
    "Chúc mừng sinh nhật",
    "", // Cook (skipped)
    "", // Cook (skipped)
    "Than phiền",
    "Không vui",
    "Cổ vũ tình yêu",
    "Ngồi",
    "Đầu hàng",
    "Đi trái",
    "Đi phải",
    "Cười",
    "Chụp ảnh",
    "Quỳ",
    "Xin chào",
    "Gãi đít",
    "Hôn gió",
    "Ôm",
    "Bắt tay",
    "Gật đầu",
    "Lắc đầu",
    "Xoay đầu",
    "Cute",
    "Going 17",
    "Tập thể dục",
    "Nhảy thầy tú",
    "Nhạc trẻ",
    "Troll",
    "", // Cook (skipped)
    "Nhạc ngủ",
    "Hip hop",
    "Nhạc đi tắm",
    "", // Cook (skipped)
    "", // Cook (skipped)
    "", // Cook (skipped)
    "Giật mình",
    "", // Cook (skipped)
    "", // Cook (skipped)
    "", // Cook (skipped)
    "Nhảy loka",
    "Nhảy cái gì đó",
    "Nhạc tik tok",
    "Nhạc EDM",
    "Nhạc rock start",
    "Nhạc timo",
    "Nhạc đê ba xi to",
    "", // Cook (skipped)
  ];

  // Keep orange color scheme
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

    visibleButtonIndexes = [];
    for (int i = 0; i < 87; i++) {
      if (_shouldShowButton(i)) {
        visibleButtonIndexes.add(i);
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

  void _sendAction(int buttonNumber) {
    // Show feedback with slight delay to improve perceived responsiveness
    final buttonIndex = buttonNumber - 1;
    setState(() {
      selectedButtonIndex = buttonIndex;
    });

    // Send the actual command with a slight delay for visual feedback
    widget.webSocketService.sendMessage(buttonNumber.toString());

    // Animation effects
    _animationController.reset();
    _animationController.forward();

    // Optional: add haptic feedback

    logger.i("Đã gửi hành động: $buttonNumber");

    // Optional: brief visual indication that command was sent
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          // Keep the selection if you want it to stay highlighted
          // or clear it if you prefer: selectedButtonIndex = null;
        });
      }
    });
  }

  void _goBack() {
    widget.webSocketService.sendMessage("Close");
    Navigator.pop(context);
  }

  // Keep existing methods
  String _getActionName(int index) {
    if (index < actionNames.length) {
      return actionNames[index].isEmpty
          ? "Hành động ${index + 1}"
          : actionNames[index];
    }
    return "Hành động ${index + 1}";
  }

  bool _shouldShowButton(int index) {
    if (index < actionNames.length) {
      return actionNames[index].isNotEmpty;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Hành động",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(77),
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
          bottom: true, // Explicitly ensure bottom safe area
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
                      // Dynamic icon based on status
                      Icon(
                        connectionStatus.contains("thành công")
                            ? Icons.check_circle
                            : connectionStatus.contains("Lỗi")
                            ? Icons.error
                            : Icons.wifi,
                        color:
                            connectionStatus.contains("thành công")
                                ? Colors.green
                                : connectionStatus.contains("Lỗi")
                                ? Colors.red
                                : Colors.orange.shade400,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          connectionStatus,
                          style: TextStyle(
                            color:
                                connectionStatus.contains("thành công")
                                    ? Colors.green.shade800
                                    : connectionStatus.contains("Lỗi")
                                    ? Colors.red.shade800
                                    : Colors.orange.shade800,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Buttons Grid - Fixed for overflow
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          MediaQuery.of(context).size.width > 600
                              ? 5
                              : MediaQuery.of(context).size.width > 400
                              ? 4
                              : 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.95, // Increased to fix overflow
                    ),
                    itemCount: visibleButtonIndexes.length,
                    itemBuilder: (context, visibleIndex) {
                      int actualIndex = visibleButtonIndexes[visibleIndex];
                      int buttonNumber = actualIndex + 1;
                      bool isSelected = selectedButtonIndex == actualIndex;

                      return AnimatedScale(
                        scale: isSelected ? 0.9 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: ActionButton(
                          index: actualIndex,
                          isSelected: isSelected,
                          onTap: () => _sendAction(buttonNumber),
                          actionName: _getActionName(
                            actualIndex,
                          ), // Pass action name
                          imagePath: _getCatImage(
                            actualIndex,
                          ), // Pass image path
                          isLoading: false, // Add this parameter
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

// Use const where possible for static widgets

// Extract button building to a separate widget class
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key, // Changed to use super parameter syntax
    required this.index,
    required this.isSelected,
    required this.onTap,
    required this.actionName,
    required this.imagePath,
    this.isLoading = false,
  }); // Removed manual super call

  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  final String actionName;
  final String imagePath;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color:
                    isSelected ? Colors.orange.withAlpha(100) : Colors.black12,
                blurRadius: isSelected ? 10 : 6,
                offset: const Offset(0, 3),
                spreadRadius: isSelected ? 1 : 0,
              ),
            ],
            border:
                isSelected
                    ? Border.all(color: Colors.orange.shade300, width: 2)
                    : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Single Hero widget - not nested
                Hero(
                  tag: "actionButton${index + 1}",
                  child: Container(
                    padding: const EdgeInsets.all(3),
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
                          color: Colors.orange.withAlpha(90),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: screenWidth * 0.05,
                      backgroundColor: Colors.white,
                      child:
                          isLoading
                              ? SizedBox(
                                width: screenWidth * 0.05,
                                height: screenWidth * 0.05,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.orange,
                                  ),
                                  strokeWidth: 2,
                                ),
                              )
                              : ClipOval(
                                child: Image.asset(
                                  imagePath,
                                  width: screenWidth * 0.09,
                                  height: screenWidth * 0.09,
                                  fit: BoxFit.cover,
                                  cacheWidth: (screenWidth * 0.18).round(),
                                  cacheHeight: (screenWidth * 0.18).round(),
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.pets,
                                      color: Colors.orange.shade300,
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
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      actionName,
                      style: TextStyle(
                        fontSize: screenWidth * 0.028,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
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
  }
}

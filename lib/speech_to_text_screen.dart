import 'package:flutter/material.dart';
import 'package:flutterdemo0/websocket_service.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:logger/logger.dart'; // Import logger

class SpeechToTextScreen extends StatefulWidget {
  final WebSocketService webSocketService;

  const SpeechToTextScreen({super.key, required this.webSocketService});

  @override
  State<SpeechToTextScreen> createState() => _SpeechToTextScreenState();
}

class _SpeechToTextScreenState extends State<SpeechToTextScreen> {
  final SpeechToText _speechToText = SpeechToText();
  final Logger _logger = Logger(); // Create logger instance
  final TextEditingController _textController = TextEditingController();
  bool _showingTextInput = false;

  static const Duration _snackBarDuration = Duration(seconds: 2);

  String _recognizedText = "";
  double _confidenceLevel = 0;
  bool _speechEnabled = false;
  List<LocaleName>? _availableLocales;
  String _selectedLocaleId = 'vi_VN'; // Vietnamese locale
  final List<String> _messageHistory = [];
  bool _showingHistory = false;
  double _historyButtonScale = 1.0; // Add this variable to your state class

  @override
  void initState() {
    super.initState();
    initSpeech();
  }

  void initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError:
          (error) => _logger.e(
            'Speech recognition error: $error',
          ), // Use logger.e for errors
      onStatus:
          (status) => _logger.i(
            'Speech recognition status: $status',
          ), // Use logger.i for info
    );

    if (_speechEnabled) {
      _availableLocales = await _speechToText.locales();

      // Check if Vietnamese is available
      final vietnameseLocale = _availableLocales?.firstWhere(
        (locale) => locale.localeId.startsWith('vi'),
        orElse: () => LocaleName('en_US', 'English (fallback)'),
      );

      setState(() {
        _selectedLocaleId = vietnameseLocale?.localeId ?? 'en_US';
      });
    }

    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: _selectedLocaleId,
      listenOptions: SpeechListenOptions(
        onDevice: false,
        cancelOnError: false, // Don't stop on errors
        partialResults: true,
      ),
      listenFor: const Duration(minutes: 30), // Long duration
      pauseFor: const Duration(minutes: 5), // Long pause allowed
    );
    setState(() {
      _confidenceLevel = 0;
      _recognizedText = "";
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _recognizedText = result.recognizedWords;
      _confidenceLevel = result.confidence;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
    widget.webSocketService.sendMessage("Close");
  }

  // Add this method to your _SpeechToTextScreenState class
  void _showTopSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: _snackBarDuration,
        margin: const EdgeInsets.only(
          bottom: 20.0,
          right: 20.0,
          left: 20.0,
          top: 50.0,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        // Position at the top instead of bottom
        dismissDirection: DismissDirection.up,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red[300]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar - removed language icon
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.red),
                      ),
                    ),

                    // Centered Title
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Nhận Dạng Tiếng Việt',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),

                    // Removed the language icon, adding empty SizedBox for balance
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              // Status Indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color:
                      _speechToText.isListening
                          ? Colors.green[100]
                          : _speechEnabled
                          ? Colors.amber[100]
                          : Colors.red[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        _speechToText.isListening
                            ? Colors.green
                            : _speechEnabled
                            ? Colors.amber
                            : Colors.red,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status text and icon
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            _speechToText.isListening
                                ? Icons.mic
                                : _speechEnabled
                                ? Icons.mic_none
                                : Icons.error_outline,
                            color:
                                _speechToText.isListening
                                    ? Colors.green
                                    : _speechEnabled
                                    ? Colors.amber
                                    : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _speechToText.isListening
                                  ? "Đang lắng nghe... Nhấn nút đỏ để dừng"
                                  : _speechEnabled
                                  ? "Nhấn vào biểu tượng micro để nói"
                                  : "Chức năng nhận dạng giọng nói không khả dụng",
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    _speechToText.isListening
                                        ? Colors.green[800]
                                        : _speechEnabled
                                        ? Colors.amber[800]
                                        : Colors.red[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Text input button for when speech is not available
                    if (!_speechEnabled)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showingTextInput = true;
                            _showingHistory = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[600],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.keyboard,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Nhập Văn Bản",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Language indicator
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/vietnam_flag.png',
                      width: 24,
                      height: 24,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              const Icon(Icons.flag, color: Colors.red),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedLocaleId.startsWith('vi')
                          ? "Tiếng Việt"
                          : "Vietnamese (using $_selectedLocaleId)",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

              // Confidence Level Indicator
              if (_confidenceLevel > 0)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Độ Chính Xác",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _confidenceLevel,
                        backgroundColor: Colors.red[100],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${(_confidenceLevel * 100).toStringAsFixed(1)}%",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),

              // Add this before the Action Buttons container
              // History Panel
              if (_showingHistory)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: const [
                              Icon(Icons.history, color: Colors.purple),
                              SizedBox(width: 8),
                              Text(
                                "Lịch Sử Văn Bản Đã Gửi",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child:
                              _messageHistory.isEmpty
                                  ? Center(
                                    child: Text(
                                      "Chưa có văn bản nào được gửi",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  )
                                  : ListView.builder(
                                    itemCount: _messageHistory.length,
                                    itemBuilder: (context, index) {
                                      final reversedIndex =
                                          _messageHistory.length - 1 - index;
                                      return Card(
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        color: Colors.grey[100],
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: Colors.purple,
                                            child: Text(
                                              '${reversedIndex + 1}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            _messageHistory[reversedIndex],
                                          ),
                                          subtitle: Text(
                                            'Đã gửi',
                                            style: TextStyle(
                                              color: Colors.green[700],
                                              fontSize: 12,
                                            ),
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(
                                              Icons.send,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () {
                                              widget.webSocketService.sendMessage(
                                                "Text: ${_messageHistory[reversedIndex]}",
                                              );
                                              _showTopSnackBar(
                                                'Đã gửi lại văn bản đến robot!',
                                                Colors.blue,
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                        ),
                        if (_messageHistory.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Send the delete command via WebSocket
                                widget.webSocketService.sendMessage("delete");

                                // Clear the local history
                                setState(() {
                                  _messageHistory.clear();
                                });

                                _showTopSnackBar(
                                  'Đã xóa lịch sử và gửi lệnh xóa đến robot!',
                                  Colors.purple,
                                );
                              },
                              icon: const Icon(
                                Icons
                                    .delete_sweep, // Changed from Icons.cleaning_services to Icons.delete_sweep
                                size: 18,
                              ),
                              label: const Text(
                                'Xóa Lịch Sử & Gửi Lệnh Xóa',
                              ), // Updated label
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors
                                        .red[400], // Changed from Colors.purple[200]
                                foregroundColor:
                                    Colors
                                        .white, // Changed from Colors.purple[900]
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 20,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              else
                // Speech Result Display or Text Input
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header with toggle button for text input
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color:
                                _showingTextInput
                                    ? Colors.blue[50]
                                    : Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Left side - Title with icon
                              Flexible(
                                child: Row(
                                  mainAxisSize:
                                      MainAxisSize.min, // Take minimum space
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      transitionBuilder: (
                                        Widget child,
                                        Animation<double> animation,
                                      ) {
                                        return ScaleTransition(
                                          scale: animation,
                                          child: child,
                                        );
                                      },
                                      child: Icon(
                                        _showingTextInput
                                            ? Icons.keyboard
                                            : Icons.speaker_notes,
                                        key: ValueKey<bool>(_showingTextInput),
                                        color:
                                            _showingTextInput
                                                ? Colors.blue
                                                : Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        transitionBuilder: (
                                          Widget child,
                                          Animation<double> animation,
                                        ) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          );
                                        },
                                        child: Text(
                                          _showingTextInput
                                              ? "Nhập Văn Bản"
                                              : "Văn Bản Nhận Dạng",
                                          key: ValueKey<bool>(
                                            _showingTextInput,
                                          ),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                _showingTextInput
                                                    ? Colors.blue
                                                    : Colors.red,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Right side - Toggle button with animation
                              Container(
                                margin: const EdgeInsets.only(
                                  left: 8,
                                ), // Add spacing from title
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _showingTextInput = !_showingTextInput;
                                      if (_showingTextInput) {
                                        _textController.text = _recognizedText;
                                      }
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          _showingTextInput
                                              ? Colors.red[400]
                                              : Colors.blue[400],
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_showingTextInput
                                                  ? Colors.red
                                                  : Colors.blue)
                                              .withAlpha(100),
                                          blurRadius: 3,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Icon with slide animation
                                        AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          transitionBuilder: (
                                            Widget child,
                                            Animation<double> animation,
                                          ) {
                                            return SlideTransition(
                                              position: Tween<Offset>(
                                                begin: const Offset(-1.0, 0.0),
                                                end: Offset.zero,
                                              ).animate(animation),
                                              child: FadeTransition(
                                                opacity: animation,
                                                child: child,
                                              ),
                                            );
                                          },
                                          child: Icon(
                                            _showingTextInput
                                                ? Icons.mic
                                                : Icons.keyboard,
                                            key: ValueKey<bool>(
                                              _showingTextInput,
                                            ),
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        // Text with slide animation
                                        AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          transitionBuilder: (
                                            Widget child,
                                            Animation<double> animation,
                                          ) {
                                            return SlideTransition(
                                              position: Tween<Offset>(
                                                begin: const Offset(1.0, 0.0),
                                                end: Offset.zero,
                                              ).animate(animation),
                                              child: FadeTransition(
                                                opacity: animation,
                                                child: child,
                                              ),
                                            );
                                          },
                                          child: Text(
                                            _showingTextInput
                                                ? "Giọng Nói"
                                                : "Bàn Phím",
                                            key: ValueKey<bool>(
                                              _showingTextInput,
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Content area - either shows text input or recognized speech
                        Expanded(
                          child:
                              _showingTextInput
                                  ? Column(
                                    children: [
                                      Expanded(
                                        child: Stack(
                                          children: [
                                            TextField(
                                              controller: _textController,
                                              maxLines: null,
                                              expands: true,
                                              textAlignVertical:
                                                  TextAlignVertical.top,
                                              // Add keyboardType to ensure full keyboard support
                                              keyboardType:
                                                  TextInputType.multiline,
                                              // Add textCapitalization for better input experience
                                              textCapitalization:
                                                  TextCapitalization.sentences,
                                              // Enable Unicode input support
                                              enableSuggestions: true,
                                              // Add text input action
                                              textInputAction:
                                                  TextInputAction.newline,
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: Colors.blue[800],
                                                fontWeight: FontWeight.w400,
                                              ),
                                              // Add onChanged to update state in real-time
                                              onChanged: (text) {
                                                setState(() {
                                                  // This forces the clear button to show/hide appropriately
                                                });
                                              },
                                              decoration: InputDecoration(
                                                hintText:
                                                    "Nhập văn bản của bạn ở đây...",
                                                hintStyle: TextStyle(
                                                  fontSize: 20,
                                                  color: Colors.blue[300],
                                                  fontWeight: FontWeight.w400,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide(
                                                    color: Colors.blue[200]!,
                                                  ),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color:
                                                            Colors.blue[200]!,
                                                      ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color:
                                                            Colors.blue[400]!,
                                                      ),
                                                    ),
                                                contentPadding:
                                                    const EdgeInsets.all(16),
                                                // Removed the suffixIcon since we're adding a floating button instead
                                              ),
                                            ),

                                            // Only show the clear button if there's text to clear
                                            if (_textController.text.isNotEmpty)
                                              Positioned(
                                                bottom: 16,
                                                right: 16,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _textController.clear();
                                                    });
                                                    _showTopSnackBar(
                                                      'Đã xóa văn bản!',
                                                      Colors.grey,
                                                    );
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue[100],
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.blue
                                                              .withAlpha(100),
                                                          blurRadius: 5,
                                                          offset: const Offset(
                                                            0,
                                                            2,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Icon(
                                                      Icons.clear,
                                                      color: Colors.blue[800],
                                                      size: 20,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          if (_textController.text.isNotEmpty) {
                                            setState(() {
                                              _recognizedText =
                                                  _textController.text;
                                            });
                                            _showTopSnackBar(
                                              'Văn bản đã được cập nhật!',
                                              Colors.blue,
                                            );
                                            setState(() {
                                              _showingTextInput = false;
                                            });
                                          }
                                        },
                                        icon: const Icon(Icons.check),
                                        label: const Text('Xác Nhận'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 24,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                  : Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.red[200]!,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        height: double.infinity,
                                        width: double.infinity,
                                        child: SingleChildScrollView(
                                          child: Text(
                                            _recognizedText.isEmpty
                                                ? "Lời nói của bạn sẽ xuất hiện ở đây..."
                                                : _recognizedText,
                                            style: TextStyle(
                                              fontSize: 20,
                                              color: Colors.red[800],
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Only show the clear button if there's text to clear
                                      if (_recognizedText.isNotEmpty)
                                        Positioned(
                                          bottom: 16,
                                          right: 16,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _recognizedText = "";
                                                _confidenceLevel = 0;
                                              });
                                              _showTopSnackBar(
                                                'Đã xóa văn bản!',
                                                Colors.grey,
                                              );
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.all(8),
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.red[100],
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.red.withAlpha(
                                                      100,
                                                    ),
                                                    blurRadius: 3,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.clear,
                                                color: Colors.red[800],
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Action Buttons
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Microphone Button
                    GestureDetector(
                      onTap:
                          _speechToText.isListening
                              ? _stopListening
                              : _startListening,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              _speechToText.isListening
                                  ? Colors.red
                                  : Colors.green,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_speechToText.isListening
                                      ? Colors.red
                                      : Colors.green)
                                  .withAlpha(
                                    76,
                                  ), // Changed from withOpacity(0.3)
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _speechToText.isListening ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),

                    // Send Button
                    if (_recognizedText.isNotEmpty &&
                        !_speechToText.isListening)
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: GestureDetector(
                          onTap: () {
                            final message = "Text: $_recognizedText";
                            widget.webSocketService.sendMessage(message);
                            setState(() {
                              _messageHistory.add(_recognizedText);
                            });
                            _showTopSnackBar(
                              'Đã gửi văn bản đến robot!',
                              Colors.green,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withAlpha(
                                    76,
                                  ), // Changed from withOpacity(0.3)
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),

                    // History Button
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showingHistory = !_showingHistory;
                            // Trigger button animation
                            _historyButtonScale =
                                1.4; // Start with larger scale
                            Future.delayed(
                              const Duration(milliseconds: 150),
                              () {
                                setState(() {
                                  _historyButtonScale = 1.0; // Return to normal
                                });
                              },
                            );
                          });
                        },
                        child: TweenAnimationBuilder(
                          tween: Tween<double>(
                            begin: _historyButtonScale,
                            end: 1.0,
                          ),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.elasticOut,
                          builder: (_, double scale, Widget? child) {
                            return Transform.scale(
                              scale: scale,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color:
                                      _showingHistory
                                          ? Colors.purple
                                          : Colors.orange,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_showingHistory
                                              ? Colors.purple
                                              : Colors.orange)
                                          .withAlpha(76),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (
                                    Widget child,
                                    Animation<double> animation,
                                  ) {
                                    return RotationTransition(
                                      turns: animation,
                                      child: ScaleTransition(
                                        scale: animation,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Icon(
                                    _showingHistory
                                        ? Icons.history_toggle_off
                                        : Icons.history,
                                    key: ValueKey<bool>(_showingHistory),
                                    color: Colors.white,
                                    size: 28,
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
            ],
          ),
        ),
      ),
    );
  }
}

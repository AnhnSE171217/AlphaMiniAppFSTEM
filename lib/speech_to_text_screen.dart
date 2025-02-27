import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutterdemo0/WebSocketService.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SpeechToTextScreen extends StatefulWidget {
  final WebSocketService webSocketService;

  const SpeechToTextScreen({super.key, required this.webSocketService});

  @override
  State<SpeechToTextScreen> createState() => _SpeechToTextScreenState();
}

class _SpeechToTextScreenState extends State<SpeechToTextScreen> {
  final SpeechToText _speechToText = SpeechToText();

  String _recognizedText = "";
  double _confidenceLevel = 0;
  bool _speechEnabled = false;
  List<LocaleName>? _availableLocales;
  String _selectedLocaleId = 'vi_VN'; // Vietnamese locale

  @override
  void initState() {
    super.initState();
    initSpeech();
  }

  void initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (error) => print('Speech recognition error: $error'),
      onStatus: (status) => print('Speech recognition status: $status'),
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
      // Remove time limits so it doesn't auto-stop
      listenFor: const Duration(minutes: 30), // Long duration
      pauseFor: const Duration(minutes: 5), // Long pause allowed
      cancelOnError: false, // Don't stop on errors
      partialResults: true, // Show partial results
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

              // Speech Result Display
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
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.speaker_notes, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              "Văn Bản Nhận Dạng",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
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
                                  .withOpacity(0.3),
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
                            widget.webSocketService.sendMessage(
                              "Text: $_recognizedText",
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Đã gửi văn bản đến robot!',
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
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

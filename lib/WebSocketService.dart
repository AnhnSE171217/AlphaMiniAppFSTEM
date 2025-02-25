import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';
import 'dart:async';

class WebSocketService {
  late WebSocketChannel _channel;
  final Logger _logger = Logger();

  // StreamController để phát sự kiện WebSocket
  final StreamController<String> _messageController = StreamController<String>.broadcast();

  // Getter cho stream để các màn hình có thể lắng nghe
  Stream<String> get messageStream => _messageController.stream;

  // Kết nối WebSocket
  void connect(String url) {
    _channel = WebSocketChannel.connect(Uri.parse(url));
    _logger.i("WebSocket connected");

    // Lắng nghe WebSocket và phát dữ liệu vào _messageController
    _channel.stream.listen(
          (message) {
        _logger.i("Received message: $message");
        _messageController.add(message);  // Phát dữ liệu vào stream
      },
      onDone: () {
        _logger.i("WebSocket connection closed.");
        _messageController.close();  // Đóng controller khi WebSocket đóng
      },
      onError: (error) {
        _logger.e("WebSocket error: $error");
        _messageController.addError(error);  // Phát lỗi vào stream
      },
    );
  }

  // Gửi tin nhắn
  void sendMessage(String message) {
    _logger.i("Sending message: $message");
    _channel.sink.add(message);
  }

  // Đóng kết nối WebSocket
  void close() {
    _channel.sink.close();
  }
}

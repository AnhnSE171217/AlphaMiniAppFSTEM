import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'websocket_service.dart'; // Import WebSocketService
import 'package:flutter_localizations/flutter_localizations.dart'; // Import localization packages

// import 'package:webview_flutter/webview_flutter.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Đảm bảo binding được khởi tạo

  // Kiểm tra nếu đang chạy trên Android và khởi tạo WebView

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Khởi tạo WebSocketService và kết nối khi ứng dụng khởi động
    final WebSocketService webSocketService = WebSocketService();
    webSocketService.connect('ws://34.143.171.53:8001/ws'); // Kết nối WebSocket

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          secondary: Colors.red,
        ),
      ),
      home: HomeScreen(
        webSocketService: webSocketService,
      ), // Truyền WebSocketService vào HomeScreen
      supportedLocales: const [
        Locale('en', 'US'), // English
        Locale('vi', 'VN'), // Vietnamese
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart'; // Add this import
import 'firebase_options.dart';
import 'home_screen.dart';
import 'websocket_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Create services globally
final WebSocketService webSocketService = WebSocketService();
final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
final Logger logger = Logger(); // Add logger instance

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Connect WebSocket in background
  Future.microtask(() {
    webSocketService.connect('ws://34.143.171.53:8001/ws');
  });

  // Sign in anonymously for simple auth

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          secondary: Colors.red,
        ),
      ),
      home: HomeScreen(webSocketService: webSocketService),
      supportedLocales: const [Locale('en', 'US'), Locale('vi', 'VN')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TestCameraScreen extends StatefulWidget {
  const TestCameraScreen({super.key});

  @override
  _TestCameraScreenState createState() => _TestCameraScreenState();
}

class _TestCameraScreenState extends State<TestCameraScreen> {
  final WebSocketChannel channel = WebSocketChannel.connect(
    Uri.parse('ws://192.169.137.40:8765'),
  );
  Uint8List? _imageBytes;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    // Đảm bảo WebView hoạt động trên Android
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse('http://192.169.137.40:8080'));

    channel.stream.listen((message) {
      setState(() {
        _imageBytes = base64Decode(message);
      });
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Camera View')),
      body: Column(
        children: [
          Expanded(
            child: WebViewWidget(controller: _controller),
          ), // Hiển thị WebView
          Expanded(
            child: Center(
              child:
                  _imageBytes != null
                      ? Image.memory(_imageBytes!)
                      : CircularProgressIndicator(),
            ),
          ),
        ],
      ),
    );
  }
}

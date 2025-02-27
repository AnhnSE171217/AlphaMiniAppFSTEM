// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:record/record.dart';  // Gói ghi âm
// import 'package:flutter/foundation.dart'; // Để sử dụng kIsWeb
// import 'package:logger/logger.dart'; // Gói Logger
// import 'WebSocketService.dart'; // Import WebSocketService

// class VoiceScreen extends StatefulWidget {
//   final WebSocketService webSocketService;  // Thêm tham số webSocketService

//   // Constructor nhận tham số webSocketService
//   const VoiceScreen({Key? key, required this.webSocketService}) : super(key: key);

//   @override
//   _VoiceScreenState createState() => _VoiceScreenState();
// }

// class _VoiceScreenState extends State<VoiceScreen> {
//   final _record = Record();  // Khởi tạo đối tượng Record
//   final Logger logger = Logger(); // Khởi tạo Logger
//   String status = "Idle";  // Biến lưu trạng thái ghi âm
//   String feedbackMessage = ""; // Biến lưu phản hồi từ WebSocket

//   @override
//   void initState() {
//     super.initState();
//     _checkMicrophoneConnection();  // Kiểm tra kết nối microphone

//     // Lắng nghe phản hồi từ WebSocket
//     widget.webSocketService.messageStream.listen((message) {
//       setState(() {
//         feedbackMessage = message;  // Cập nhật phản hồi nhận được
//       });
//       // Hiển thị phản hồi trong SnackBar
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text('Received: $message'),
//         duration: Duration(seconds: 2),
//       ));

//       // Log phản hồi vào console
//       logger.i("WebSocket response: $message");
//     });
//   }

//   // Kiểm tra quyền truy cập và khả năng kết nối microphone
//   void _checkMicrophoneConnection() async {
//     bool hasPermission = await _record.hasPermission();  // Kiểm tra quyền microphone
//     if (hasPermission) {
//       setState(() {
//         status = "Microphone is available and ready to use.";
//       });
//       logger.i("Microphone is available.");
//     } else {
//       setState(() {
//         status = "Microphone permission is not granted.";
//       });
//       logger.e("Microphone permission is not granted.");
//     }
//   }

//   // Bắt đầu hoặc dừng ghi âm
//   void _toggleRecording() async {
//     if (status == "Recording in progress...") {
//       // Dừng ghi âm
//       _record.stop().then((_) async {
//         setState(() {
//           status = "Stopped recording!";
//         });

//         // Chỉ kiểm tra và xử lý file nếu không phải trên Web
//         if (!kIsWeb) {
//           final file = File('audio_test.wav');
//           if (await file.exists()) {
//             List<int> fileBytes = await file.readAsBytes();
//             String base64String = base64Encode(fileBytes);  // Chuyển đổi thành Base64

//             // Gửi dữ liệu Base64 qua WebSocket
//             widget.webSocketService.sendMessage(base64String);
//             logger.i("Audio data sent to WebSocket.");

//             // Hiển thị thông báo gửi dữ liệu trong SnackBar
//             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//               content: Text('Audio data sent to WebSocket'),
//               duration: Duration(seconds: 2),
//             ));
//           } else {
//             setState(() {
//               status = "Recording file does not exist.";
//             });
//             logger.e("Recording file does not exist.");
//           }
//         } else {
//           // Trường hợp trên Web, bỏ qua thao tác với file
//           logger.w("File operations are not supported in Flutter Web.");
//         }
//       });
//     } else {
//       // Bắt đầu ghi âm
//       _record.start(path: 'audio_test.wav').then((_) {
//         setState(() {
//           status = "Recording in progress...";
//         });
//         logger.i("Recording started.");
//       });
//     }
//   }

//   // Gửi lệnh thử nghiệm qua WebSocket khi nhấn nút
//   void _sendTestCommand() async {
//     if (!kIsWeb) {
//       final file = File('audio_test.wav');
//       if (await file.exists()) {
//         List<int> fileBytes = await file.readAsBytes();
//         String base64String = base64Encode(fileBytes);  // Chuyển đổi tệp thành Base64

//         // Gửi dữ liệu Base64 qua WebSocket
//         widget.webSocketService.sendMessage(base64String);
//         logger.i("Test command with Base64 data sent to WebSocket.");

//         // Hiển thị thông báo gửi dữ liệu trong SnackBar
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           content: Text('Test command sent to WebSocket'),
//           duration: Duration(seconds: 2),
//         ));
//       } else {
//         logger.e("No audio file found to send.");
//       }
//     } else {
//       logger.w("File operations are not supported in Flutter Web.");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Voice Commands'),
//         backgroundColor: Colors.red,
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(status, style: TextStyle(fontSize: 20, color: Colors.black)),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _toggleRecording,
//               child: Text(status == "Recording in progress..." ? "Stop Recording" : "Start Recording"),
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _sendTestCommand,  // Gửi dữ liệu Base64 thử nghiệm
//               child: Text("Send Command to WebSocket"),
//             ),
//             SizedBox(height: 20),
//             // Hiển thị phản hồi từ WebSocket (nếu có)
//             if (feedbackMessage.isNotEmpty)
//               Text("Received from WebSocket: $feedbackMessage", style: TextStyle(color: Colors.green, fontSize: 16)),
//           ],
//         ),
//       ),
//     );
//   }
// }

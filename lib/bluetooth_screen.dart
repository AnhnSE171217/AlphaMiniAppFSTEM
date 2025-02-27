// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:logger/logger.dart';

// class BluetoothScreen extends StatefulWidget {
//   const BluetoothScreen({super.key});

//   @override
//   _BluetoothScreenState createState() => _BluetoothScreenState();
// }

// class _BluetoothScreenState extends State<BluetoothScreen> {
//   FlutterBluePlus flutterBlue = FlutterBluePlus();  // Khởi tạo đối tượng FlutterBluePlus
//   final Logger logger = Logger();

//   List<BluetoothDevice> devicesList = [];
//   BluetoothDevice? connectedDevice;
//   BluetoothCharacteristic? characteristic;
//   bool isScanning = false;

//   @override
//   void initState() {
//     super.initState();
//     _requestPermissions(); // Yêu cầu quyền vị trí khi vào BluetoothScreen
//   }

//   // Yêu cầu quyền vị trí
//   void _requestPermissions() async {
//     PermissionStatus status = await Permission.location.request();
//     if (status.isGranted) {
//       startScan(); // Nếu quyền vị trí đã được cấp, bắt đầu quét
//     } else {
//       logger.e("Location permission is required to scan for Bluetooth devices.");
//     }
//   }

//   // Bắt đầu quét các thiết bị Bluetooth
//   void startScan() async {
//     setState(() {
//       isScanning = true;
//       devicesList.clear();  // Xóa danh sách thiết bị cũ khi quét lại
//     });

//     FlutterBluePlus.startScan(timeout: Duration(seconds: 4));

//     FlutterBluePlus.scanResults.listen((scanResults) {
//       setState(() {
//         for (var result in scanResults) {
//           devicesList.add(result.device);  // Thêm thiết bị vào danh sách
//         }
//       });
//     }, onDone: () {
//       setState(() {
//         isScanning = false;  // Dừng quét khi kết thúc
//       });
//     });
//   }

//   // Dừng quét các thiết bị Bluetooth
//   void stopScan() async {
//     await FlutterBluePlus.stopScan();
//     setState(() {
//       isScanning = false;
//     });
//   }

//   // Kết nối với thiết bị Bluetooth
//   void connectToDevice(BluetoothDevice device) async {
//     await device.connect();
//     setState(() {
//       connectedDevice = device; // Lưu thiết bị đã kết nối
//     });

//     // Lấy các đặc trưng (characteristics) của thiết bị Bluetooth
//     List<BluetoothService> services = await device.discoverServices();
//     BluetoothService? targetService;

//     for (var service in services) {
//       // Tìm một characteristic có thể gửi dữ liệu (ví dụ, viết dữ liệu vào thiết bị)
//       for (var characteristic in service.characteristics) {
//         if (characteristic.properties.write) {
//           targetService = service;
//           this.characteristic = characteristic;
//           break;
//         }
//       }
//     }
//   }

//   // Ngắt kết nối với thiết bị
//   void disconnectDevice() async {
//     if (connectedDevice != null) {
//       await connectedDevice!.disconnect();
//       setState(() {
//         connectedDevice = null;
//       });
//     }
//   }

//   // Gửi tin nhắn "Hello World" đến thiết bị kết nối
//   void sendHelloWorld() async {
//     if (characteristic != null) {
//       try {
//         await characteristic!.write([72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100]); // Gửi "Hello World" (Mã ASCII)
//         logger.i("Message 'Hello World' sent to device.");
//       } catch (e) {
//         logger.e("Failed to send message: $e");
//       }
//     } else {
//       logger.e("No characteristic available to send data.");
//     }
//   }

//   @override
//   void dispose() {
//     FlutterBluePlus.stopScan();  // Dừng quét khi widget bị hủy
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Bluetooth Screen'),
//         backgroundColor: Colors.orange,
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: ElevatedButton(
//               onPressed: isScanning ? stopScan : startScan,
//               child: Text(isScanning ? 'Stop Scanning' : 'Start Scanning'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue,
//               ),
//             ),
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: devicesList.length,
//               itemBuilder: (context, index) {
//                 BluetoothDevice device = devicesList[index];
//                 return ListTile(
//                   title: Text(device.name.isEmpty ? "Unnamed Device" : device.name),
//                   subtitle: Text(device.id.toString()),
//                   trailing: ElevatedButton(
//                     onPressed: () => connectToDevice(device),
//                     child: Text('Connect'),
//                   ),
//                 );
//               },
//             ),
//           ),
//           if (connectedDevice != null) ...[
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Text('Connected to: ${connectedDevice!.name}'),
//             ),
//             ElevatedButton(
//               onPressed: disconnectDevice,
//               child: const Text('Disconnect'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red,
//               ),
//             ),
//             ElevatedButton(
//               onPressed: sendHelloWorld,  // Gửi tin nhắn Hello World
//               child: const Text('Send Hello World'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//               ),
//             ),
//           ],
//         ],
//       ),
//       backgroundColor: Colors.white,
//     );
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'package:device_info_plus/device_info_plus.dart';

class BluetoothConnectionPage extends StatefulWidget {
  const BluetoothConnectionPage({super.key});

  @override
  State<BluetoothConnectionPage> createState() =>
      _BluetoothConnectionPageState();
}

class _BluetoothConnectionPageState extends State<BluetoothConnectionPage>
    with SingleTickerProviderStateMixin {
  final Logger logger = Logger();
  bool _isBluetoothEnabled = false;
  bool _isScanning = false;
  List<ScanResult> _scanResults = [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  bool _hasPermissions = false;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  Timer? _scanTimeout;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _adapterStateSubscription?.cancel();
    _scanTimeout?.cancel();
    // Ensure scanning is stopped when the page is disposed
    if (_isScanning) {
      _stopScanning();
    }
    super.dispose();
  }

  Future<void> _initBluetooth() async {
    // Request permissions first
    await _requestPermissions();

    // Then check Bluetooth status
    await _checkBluetoothStatus();
  }

  Future<void> _requestPermissions() async {
    logger.i("Requesting Bluetooth permissions");

    // Define permissions based on platform and version
    List<Permission> permissionsToRequest = [];

    // Basic location permissions needed for BLE scanning
    permissionsToRequest.addAll([
      Permission.location,
      Permission.locationWhenInUse,
    ]);

    // For Android, check SDK version to determine needed permissions
    if (Platform.isAndroid) {
      // Add Bluetooth permissions based on Android version
      if (await _isAndroid12OrHigher()) {
        // Android 12+ requires specific Bluetooth permissions
        permissionsToRequest.addAll([
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
        ]);
      } else {
        // Older Android versions
        permissionsToRequest.add(Permission.bluetooth);
      }
    }

    // Request permissions and store results
    Map<Permission, PermissionStatus> statuses =
        await permissionsToRequest.request();

    // Log results for debugging
    logger.d("Permission statuses: $statuses");

    // Check if all required permissions are granted
    bool allGranted = true;
    for (var entry in statuses.entries) {
      if (!entry.value.isGranted) {
        allGranted = false;
        logger.w("Permission not granted: ${entry.key}");
      }
    }

    setState(() {
      _hasPermissions = allGranted;
    });

    // Show message if permissions are not granted
    if (!allGranted) {
      logger.w("Not all permissions are granted");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cần cấp đầy đủ quyền để sử dụng tính năng Bluetooth',
            ),
            action: SnackBarAction(
              label: 'CÀI ĐẶT',
              onPressed: () {
                openAppSettings();
              },
            ),
          ),
        );
      }
    }
  }

  Future<bool> _isAndroid12OrHigher() async {
    if (Platform.isAndroid) {
      return (await DeviceInfoPlugin().androidInfo).version.sdkInt >= 31;
    }
    return false;
  }

  Future<void> _checkBluetoothStatus() async {
    try {
      logger.i("Checking Bluetooth status");
      // Check if Bluetooth is available on the device
      bool isAvailable = await FlutterBluePlus.isSupported;
      if (!isAvailable) {
        logger.w("Bluetooth is not available on this device");
        setState(() {
          _isBluetoothEnabled = false;
        });
        return;
      }

      // Check if Bluetooth is turned on
      bool isOn =
          await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
      logger.i("Bluetooth is turned on: $isOn");

      setState(() {
        _isBluetoothEnabled = isOn;
      });

      // Listen for adapter state changes
      _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
        logger.i("Bluetooth adapter state changed: $state");
        setState(() {
          _isBluetoothEnabled = state == BluetoothAdapterState.on;
        });

        // If Bluetooth was just turned on and we're not scanning, start scanning
        if (state == BluetoothAdapterState.on &&
            !_isScanning &&
            _hasPermissions) {
          _startScanning();
        }

        // If Bluetooth was turned off and we're scanning, stop scanning
        if (state == BluetoothAdapterState.off && _isScanning) {
          _stopScanning();
        }
      });

      // If Bluetooth is already on and we have permissions, start scanning
      if (isOn && _hasPermissions) {
        _startScanning();
      }
    } catch (e) {
      logger.e("Error checking Bluetooth status: $e");
      setState(() {
        _isBluetoothEnabled = false;
      });
      if (mounted) {
        // Add this check
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi kiểm tra trạng thái Bluetooth: $e')),
        );
      }
    }
  }

  Future<void> _startScanning() async {
    if (!_hasPermissions) {
      logger.w("Attempting to scan without permissions");
      if (mounted) {
        // Add this check
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng cấp quyền để sử dụng Bluetooth'),
          ),
        );
      }
      await _requestPermissions();
      if (!_hasPermissions) return;
    }

    if (!_isBluetoothEnabled) {
      logger.w("Attempting to scan with Bluetooth disabled");
      if (mounted) {
        // Add this check
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng bật Bluetooth để quét thiết bị'),
          ),
        );
      }
      return;
    }

    // Cancel any existing scan
    await _stopScanning();

    // Add a more substantial delay to ensure previous scan is completely stopped
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isScanning = true;
      _scanResults = [];
    });

    logger.i("Starting Bluetooth scan");

    try {
      // Set up the scan subscription first
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) {
          logger.d("Scan found ${results.length} devices");

          // Print all devices for debugging
          for (var r in results) {
            final deviceName = r.device.platformName;
            final advName = r.advertisementData.advName;
            final hasServiceUUIDs = r.advertisementData.serviceUuids.isNotEmpty;
            final hasManufacturerData =
                r.advertisementData.manufacturerData.isNotEmpty;
            final hasSvcData = r.advertisementData.serviceData.isNotEmpty;

            logger.d(
              "Device: $deviceName / $advName (Service UUIDs: $hasServiceUUIDs, Mfg Data: $hasManufacturerData, Svc Data: $hasSvcData)",
            );
          }

          // Use a more permissive filter - accept any device
          setState(() {
            _scanResults = results.toList();
          });
        },
        onError: (error) {
          logger.e("Scan error: $error");
          setState(() {
            _isScanning = false;
          });
          if (mounted) {
            // Add this check
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Lỗi khi quét: $error')));
          }
        },
      );

      // Start scanning with a timeout
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidScanMode: AndroidScanMode.lowLatency,
      );

      // Set a separate timeout to ensure scan stops even if the callback fails
      _scanTimeout = Timer(const Duration(seconds: 16), () {
        if (_isScanning) {
          logger.w("Scan timeout reached. Forcing scan stop.");
          _stopScanning();
        }
      });
    } catch (e) {
      logger.e("StartScan exception: $e");
      setState(() {
        _isScanning = false;
      });
      if (mounted) {
        // Add this check
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi bắt đầu quét: $e')));
      }
    }
  }

  Future<void> _stopScanning() async {
    logger.i("Stopping any active scan");
    _scanTimeout?.cancel();

    if (_scanSubscription != null) {
      await _scanSubscription!.cancel();
      _scanSubscription = null;
    }

    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      logger.e("Error stopping scan: $e");
    }

    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  // CredentialsInputScreen class remains the same...

  void _goBack() {
    Navigator.pop(context);
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    logger.i("Connecting to device: ${device.remoteId}");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CredentialsInputScreen(device: device),
      ),
    );
  }

  Future<void> _turnOnBluetooth() async {
    try {
      logger.i("Attempting to turn on Bluetooth");
      // On Android, we can try to prompt the user to enable Bluetooth
      if (await FlutterBluePlus.adapterState.first !=
          BluetoothAdapterState.on) {
        await FlutterBluePlus.turnOn();
      }
    } catch (e) {
      logger.e("Error turning on Bluetooth: $e");
      if (mounted) {
        // Add this check
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vui lòng bật Bluetooth từ cài đặt: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
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
        title: const Text(
          "Connect to Robot",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade800,
              Colors.blue.shade500,
              Colors.indigo.shade800,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Bluetooth status and scan button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isBluetoothEnabled
                              ? Icons.bluetooth_connected
                              : Icons.bluetooth_disabled,
                          color:
                              _isBluetoothEnabled
                                  ? Colors.white
                                  : Colors.white.withAlpha(128),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bluetooth: ${_isBluetoothEnabled ? "Enabled" : "Disabled"}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                _isBluetoothEnabled
                                    ? Colors.white
                                    : Colors.white.withAlpha(128),
                          ),
                        ),
                      ],
                    ),
                    _isBluetoothEnabled
                        ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue.shade800,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed:
                              _isScanning ? _stopScanning : _startScanning,
                          child: Text(
                            _isScanning ? 'Dừng quét' : 'Quét thiết bị',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        )
                        : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue.shade800,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _turnOnBluetooth,
                          child: const Text(
                            'Bật Bluetooth',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                  ],
                ),

                const SizedBox(height: 16),

                // Permissions status
                if (!_hasPermissions)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withAlpha(77)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Thiếu quyền truy cập',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ứng dụng cần quyền Bluetooth và Vị trí để hoạt động',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(204),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _requestPermissions,
                          child: const Text(
                            'CẤP QUYỀN',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Device list
                Expanded(
                  child:
                      _isScanning
                          ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Đang quét thiết bị Bluetooth...',
                                style: TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Đã tìm thấy: ${_scanResults.length} thiết bị',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(179),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                          : _scanResults.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bluetooth_searching,
                                  size: 64,
                                  color: Colors.white.withAlpha(128),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _isBluetoothEnabled
                                      ? 'Không tìm thấy thiết bị nào. Vui lòng quét lại.'
                                      : 'Vui lòng bật Bluetooth để quét thiết bị.',
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(204),
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                if (_isBluetoothEnabled && !_isScanning)
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Quét lại'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.blue.shade800,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: _startScanning,
                                  ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            itemCount: _scanResults.length,
                            itemBuilder: (context, index) {
                              final result = _scanResults[index];
                              final device = result.device;
                              final advertisementData =
                                  result.advertisementData;

                              // Get device name from advertisement data first, then platform name
                              final name =
                                  advertisementData.advName.isNotEmpty
                                      ? advertisementData.advName
                                      : device.platformName.isNotEmpty
                                      ? device.platformName
                                      : "Thiết bị không xác định";

                              final rssi = result.rssi;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(38),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(51),
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(26),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.bluetooth,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    name, // Use the derived name
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tín hiệu: $rssi dBm',
                                        style: TextStyle(
                                          color: Colors.white.withAlpha(179),
                                        ),
                                      ),
                                      Text(
                                        'MAC: ${device.remoteId}',
                                        style: TextStyle(
                                          color: Colors.white.withAlpha(179),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.blue.shade800,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () => _connectToDevice(device),
                                    child: const Text('Kết nối'),
                                  ),
                                  onTap: () => _connectToDevice(device),
                                ),
                              );
                            },
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

class CredentialsInputScreen extends StatefulWidget {
  final BluetoothDevice device;

  const CredentialsInputScreen({super.key, required this.device});

  @override
  State<CredentialsInputScreen> createState() => _CredentialsInputScreenState();
}

class _CredentialsInputScreenState extends State<CredentialsInputScreen> {
  final Logger logger = Logger();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isConnecting = true;
  bool _isConnected = false;
  bool _isSendingCredentials = false;
  bool _credentialsSent = false;
  String _connectionStatus = "Đang khởi tạo kết nối...";

  // For Bluetooth communication
  BluetoothCharacteristic? _dataCharacteristic;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  int _connectionAttempts = 0;
  static const int maxConnectionAttempts = 3;

  @override
  void initState() {
    super.initState();
    _connectToDevice();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    // Disconnect when leaving the screen
    try {
      widget.device.disconnect();
    } catch (e) {
      logger.e("Error disconnecting: $e");
    }
    super.dispose();
  }

  Future<void> _connectToDevice() async {
    setState(() {
      _connectionStatus = "Đang kết nối với thiết bị...";
      _connectionAttempts++;
    });

    try {
      // Setup connection listener
      _connectionSubscription = widget.device.connectionState.listen(
        (state) {
          logger.i("Connection state changed: $state");
          if (state == BluetoothConnectionState.connected) {
            _onDeviceConnected();
          } else if (state == BluetoothConnectionState.disconnected) {
            setState(() {
              _isConnected = false;
              _connectionStatus = "Mất kết nối với thiết bị.";
            });

            // Try to reconnect if disconnected unexpectedly
            if (_isConnecting && _connectionAttempts < maxConnectionAttempts) {
              logger.i(
                "Attempting to reconnect. Attempt: $_connectionAttempts",
              );
              Future.delayed(const Duration(seconds: 2), () {
                _connectToDevice();
              });
            }
          }
        },
        onError: (error) {
          logger.e("Connection state error: $error");
          setState(() {
            _isConnected = false;
            _connectionStatus = "Lỗi theo dõi kết nối: $error";
          });
        },
      );

      // Connect to device with timeout
      bool connected = false;
      try {
        logger.i("Attempting to connect to device: ${widget.device.remoteId}");

        // Try to disconnect first to ensure a clean connection
        try {
          await widget.device.disconnect();
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          logger.d("Disconnect before connect error (can be ignored): $e");
        }

        await widget.device.connect(
          timeout: const Duration(seconds: 15),
          autoConnect: false,
        );
        connected = true;
        logger.i("Successfully connected to device");
      } catch (e) {
        if (e.toString().contains('already connected')) {
          logger.i("Device was already connected");
          connected = true;
        } else {
          rethrow;
        }
      }

      if (!connected) {
        throw Exception("Không thể kết nối với thiết bị");
      }
    } catch (e) {
      logger.e("Connection error: $e");
      setState(() {
        _connectionStatus = "Lỗi kết nối: $e";
        _isConnecting = _connectionAttempts < maxConnectionAttempts;
      });

      // Try to reconnect
      if (_connectionAttempts < maxConnectionAttempts) {
        logger.i(
          "Will attempt to reconnect in 3 seconds. Attempt: $_connectionAttempts",
        );
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _connectToDevice();
          }
        });
      }
    }
  }

  Future<void> _onDeviceConnected() async {
    logger.i("Connected to device: ${widget.device.remoteId}");

    setState(() {
      _connectionStatus = "Đã kết nối. Đang tìm kiếm dịch vụ...";
    });

    try {
      // Discover services
      logger.i("Discovering services...");
      List<BluetoothService> services = await widget.device.discoverServices();
      logger.i("Discovered ${services.length} services");

      // Find suitable service and characteristic
      bool found = false;

      // Log all services for debugging
      for (BluetoothService service in services) {
        logger.d("Service: ${service.uuid}");
        for (BluetoothCharacteristic c in service.characteristics) {
          logger.d("  Characteristic: ${c.uuid}, props: ${c.properties}");
        }
      }

      // Find any writable characteristic
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse) {
            logger.i("Found writable characteristic: ${characteristic.uuid}");
            _dataCharacteristic = characteristic;
            found = true;
            break;
          }
        }
        if (found) break;
      }

      setState(() {
        _isConnecting = false;
        _isConnected = true;
        if (found) {
          _connectionStatus =
              "Kết nối thành công! Vui lòng nhập thông tin đăng nhập.";
        } else {
          _connectionStatus = "Không tìm thấy kênh giao tiếp phù hợp.";
        }
      });
    } catch (e) {
      logger.e("Service discovery error: $e");
      setState(() {
        _connectionStatus = "Lỗi dịch vụ: $e";
        _isConnecting = false;
      });
    }
  }

  Future<void> _sendCredentials() async {
    if (!_isConnected) {
      if (mounted) {
        // Add this check
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có kết nối với thiết bị.')),
        );
      }
      return;
    }

    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      if (mounted) {
        // Add this check
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập tài khoản và mật khẩu')),
        );
      }
      return;
    }

    setState(() {
      _isSendingCredentials = true;
      _connectionStatus = "Đang gửi thông tin đăng nhập...";
    });

    try {
      if (_dataCharacteristic != null) {
        // Create a map of the credentials
        Map<String, String> credentials = {
          'username': _usernameController.text,
          'password': _passwordController.text,
        };

        // Convert to JSON string and then to bytes
        String jsonCredentials = jsonEncode(credentials);
        List<int> bytes = utf8.encode(jsonCredentials);

        logger.i("Prepared to send data: $jsonCredentials");

        // Check if the characteristic can write
        if (_dataCharacteristic!.properties.write) {
          // Write to the characteristic with response
          await _dataCharacteristic!.write(bytes, withoutResponse: false);
          logger.i("Credentials sent successfully (with response)");
        } else if (_dataCharacteristic!.properties.writeWithoutResponse) {
          // Write without response
          await _dataCharacteristic!.write(bytes, withoutResponse: true);
          logger.i("Credentials sent successfully (without response)");
        } else {
          throw Exception("Characteristic does not support writing");
        }

        // Simulate delay to allow device to process
        await Future.delayed(const Duration(seconds: 1));

        setState(() {
          _isSendingCredentials = false;
          _credentialsSent = true;
          _connectionStatus = "Đã gửi thông tin đăng nhập thành công!";
        });
      } else {
        throw Exception("No suitable data characteristic found");
      }
    } catch (e) {
      logger.e("Error sending credentials: $e");
      setState(() {
        _isSendingCredentials = false;
        _connectionStatus = "Lỗi gửi dữ liệu: $e";
      });

      if (mounted) {
        // Add this check
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnecting) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(77),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          title: const Text(
            "Đang kết nối với robot",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          centerTitle: true,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade800,
                Colors.blue.shade500,
                Colors.indigo.shade800,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _connectionStatus,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_credentialsSent) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: const Text(
            "Kết nối hoàn tất",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          centerTitle: true,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade800,
                Colors.blue.shade500,
                Colors.indigo.shade800,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 80),
                const SizedBox(height: 20),
                const Text(
                  'Đã gửi thông tin thành công',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Robot Alpha Mini đã sẵn sàng sử dụng',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withAlpha(179),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue.shade800,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Hoàn tất',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(77),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        title: const Text(
          "Thông tin đăng nhập",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade800,
              Colors.blue.shade500,
              Colors.indigo.shade800,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connected device info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(38),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withAlpha(51),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(26),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bluetooth_connected,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đã kết nối với: ${widget.device.platformName.isNotEmpty ? widget.device.platformName : "Thiết bị không xác định"}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${widget.device.remoteId}',
                              style: TextStyle(
                                color: Colors.white.withAlpha(179),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Status message
                Text(
                  _connectionStatus,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Credentials input form
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Tài khoản',
                    labelStyle: TextStyle(color: Colors.white.withAlpha(230)),
                    filled: true,
                    fillColor: Colors.white.withAlpha(38),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withAlpha(51),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white, width: 1),
                    ),
                    prefixIcon: const Icon(Icons.person, color: Colors.white),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    labelStyle: TextStyle(color: Colors.white.withAlpha(230)),
                    filled: true,
                    fillColor: Colors.white.withAlpha(38),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withAlpha(51),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white, width: 1),
                    ),
                    prefixIcon: const Icon(Icons.lock, color: Colors.white),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),

                const SizedBox(height: 32),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed:
                        _isConnected && !_isSendingCredentials
                            ? _sendCredentials
                            : null,
                    child:
                        _isSendingCredentials
                            ? const CircularProgressIndicator()
                            : const Text(
                              'Gửi thông tin đăng nhập',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'WebSocketService.dart';

class BluetoothConnectionPage extends StatefulWidget {
  final WebSocketService webSocketService;

  const BluetoothConnectionPage({super.key, required this.webSocketService});

  @override
  _BluetoothConnectionPageState createState() =>
      _BluetoothConnectionPageState();
}

class _BluetoothConnectionPageState extends State<BluetoothConnectionPage>
    with SingleTickerProviderStateMixin {
  final Logger logger = Logger();
  bool _isBluetoothEnabled = false;
  bool _isScanning = false;
  List<ScanResult> _scanResults = [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  String connectionStatus = "Connecting to WebSocket...";

  @override
  void initState() {
    super.initState();
    _checkBluetoothStatus();
    _requestPermissions();

    // Send initial message to WebSocket - exactly like in ActionScreen
    widget.webSocketService.sendMessage("Bluetooth");

    // Set up listener for WebSocket messages - exactly like in ActionScreen
    widget.webSocketService.messageStream.listen(
      (message) {
        logger.i("Received message: $message");
      },
      onError: (error) {
        setState(() {
          connectionStatus = "Connection error: $error";
        });
      },
      onDone: () {
        setState(() {
          connectionStatus = "Connection closed";
        });
      },
    );

    setState(() {
      connectionStatus = "Connected successfully!";
    });
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    // Send close message before dispose - exactly like in ActionScreen
    widget.webSocketService.sendMessage("Close");
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
  }

  Future<void> _checkBluetoothStatus() async {
    FlutterBluePlus.isOn.then((isOn) {
      setState(() {
        _isBluetoothEnabled = isOn;
      });
    });

    FlutterBluePlus.adapterState.listen((state) {
      setState(() {
        _isBluetoothEnabled = state == BluetoothAdapterState.on;
      });
    });
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
      _scanResults = [];
    });

    // Log via the same logger instance as used for WebSocket messages
    logger.i("Starting Bluetooth scan");

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        _scanResults =
            results.where((r) {
              final deviceName = r.advertisementData.advName.toLowerCase();
              final platformName = r.device.platformName.toLowerCase();
              return deviceName.contains('Mini') ||
                  platformName.contains('Mini') ||
                  r.advertisementData.manufacturerData.containsKey(0x0001);
            }).toList();
      });
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10)).then((_) {
      setState(() {
        _isScanning = false;
      });
    });
  }

  void _stopScanning() {
    FlutterBluePlus.stopScan();
    setState(() {
      _isScanning = false;
    });
  }

  void _goBack() {
    // Send close message before navigation - exactly like in ActionScreen
    widget.webSocketService.sendMessage("Close");
    Navigator.pop(context);
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    // Send device connection message to WebSocket
    widget.webSocketService.sendMessage("Connect:${device.remoteId}");
    logger.i("Sent connection request for device: ${device.remoteId}");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => WiFiConnectionScreen(
              device: device,
              webSocketService: widget.webSocketService,
            ),
      ),
    );
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
                // WebSocket connection status
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
                        child: const Icon(Icons.wifi, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'WebSocket Status',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              connectionStatus,
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

                // Bluetooth status and scan button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bluetooth: ${_isBluetoothEnabled ? "Enabled" : "Disabled"}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isBluetoothEnabled ? Colors.white : Colors.grey,
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
                          _isBluetoothEnabled
                              ? (_isScanning ? _stopScanning : _startScanning)
                              : null,
                      child: Text(
                        _isScanning ? 'Stop Scan' : 'Scan for Devices',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Device list
                _isScanning
                    ? const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Scanning for Alpha Mini robots...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    )
                    : Expanded(
                      child:
                          _scanResults.isEmpty
                              ? Center(
                                child: Text(
                                  _isBluetoothEnabled
                                      ? 'No Alpha Mini robots found. Try scanning again.'
                                      : 'Please enable Bluetooth to scan for devices.',
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(204),
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
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
                                          : "Unknown Device";

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
                                      subtitle: Text(
                                        'Signal: $rssi dBm\nMAC: ${device.remoteId}',
                                        style: TextStyle(
                                          color: Colors.white.withAlpha(179),
                                        ),
                                      ),
                                      trailing: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.blue.shade800,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        onPressed:
                                            () => _connectToDevice(device),
                                        child: const Text('Connect'),
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

class WiFiConnectionScreen extends StatefulWidget {
  final BluetoothDevice device;
  final WebSocketService webSocketService;

  const WiFiConnectionScreen({
    super.key,
    required this.device,
    required this.webSocketService,
  });

  @override
  _WiFiConnectionScreenState createState() => _WiFiConnectionScreenState();
}

class _WiFiConnectionScreenState extends State<WiFiConnectionScreen> {
  final Logger logger = Logger();
  bool _isConnecting = true;
  bool _isScanning = true;
  List<String> _wifiNetworks = [];
  String? _selectedNetwork;
  final TextEditingController _passwordController = TextEditingController();
  bool _isConnectingToWifi = false;
  bool _connectionSuccessful = false;
  String connectionStatus = "Initializing WiFi setup...";

  @override
  void initState() {
    super.initState();

    // Send WiFi setup message to WebSocket
    widget.webSocketService.sendMessage("WiFiSetup:${widget.device.remoteId}");

    // Set up listener for WebSocket messages
    widget.webSocketService.messageStream.listen(
      (message) {
        logger.i("Received WiFi message: $message");

        // Handle different message types from server
        if (message.startsWith("NETWORKS:")) {
          // Example message: "NETWORKS:Home_WiFi,Office_Secure,Guest_Network"
          final networks = message.substring(9).split(',');
          setState(() {
            _wifiNetworks = networks;
            _isScanning = false;
          });
        } else if (message == "CONNECT_SUCCESS") {
          setState(() {
            _isConnectingToWifi = false;
            _connectionSuccessful = true;
          });
        } else if (message.startsWith("STATUS:")) {
          setState(() {
            connectionStatus = message.substring(7);
          });
        }
      },
      onError: (error) {
        setState(() {
          connectionStatus = "Connection error: $error";
        });
      },
      onDone: () {
        setState(() {
          connectionStatus = "Connection closed";
        });
      },
    );

    _connectToDevice();
  }

  @override
  void dispose() {
    // Send close message before dispose
    widget.webSocketService.sendMessage("CloseWiFiSetup");
    super.dispose();
  }

  Future<void> _connectToDevice() async {
    // Simulate connecting to the Bluetooth device
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isConnecting = false;
    });

    // Now using WebSocket to get WiFi networks instead of simulation
    widget.webSocketService.sendMessage("ScanWiFi");
  }

  Future<void> _connectToWifi() async {
    if (_selectedNetwork == null || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a network and enter password'),
        ),
      );
      return;
    }

    setState(() {
      _isConnectingToWifi = true;
    });

    // Send WiFi credentials via WebSocket
    widget.webSocketService.sendMessage(
      "WiFiConnect:$_selectedNetwork:${_passwordController.text}",
    );
    logger.i("Sent WiFi connection request for network: $_selectedNetwork");
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
            "Connecting to Robot",
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
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 20),
                Text(
                  'Connecting to Alpha Mini robot...',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_connectionSuccessful) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: const Text(
            "Connection Complete",
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
                Text(
                  'Successfully connected to $_selectedNetwork',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Alpha Mini robot is now ready to use',
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
                    'Done',
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
          "WiFi Setup",
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
                              'Connected to: ${widget.device.platformName.isNotEmpty ? widget.device.platformName : "Unknown Device"}',
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

                const Text(
                  'Available WiFi Networks:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                _isScanning
                    ? Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            'Scanning for networks...',
                            style: TextStyle(
                              color: Colors.white.withAlpha(204),
                            ),
                          ),
                        ],
                      ),
                    )
                    : Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(26),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withAlpha(51),
                            width: 1,
                          ),
                        ),
                        child: ListView.builder(
                          itemCount: _wifiNetworks.length,
                          itemBuilder: (context, index) {
                            final network = _wifiNetworks[index];
                            return RadioListTile<String>(
                              title: Text(
                                network,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              value: network,
                              groupValue: _selectedNetwork,
                              activeColor: Colors.white,
                              fillColor: WidgetStateProperty.all(Colors.white),
                              onChanged: (value) {
                                setState(() {
                                  _selectedNetwork = value;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),

                if (_selectedNetwork != null) ...[
                  const SizedBox(height: 24),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password for $_selectedNetwork',
                      labelStyle: TextStyle(color: Colors.white.withAlpha(204)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withAlpha(128),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      prefixIcon: const Icon(
                        Icons.wifi_password,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child:
                        _isConnectingToWifi
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : ElevatedButton(
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
                              onPressed: _connectToWifi,
                              child: const Text(
                                'Connect to WiFi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

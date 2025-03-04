import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

class BluetoothConnectionPage extends StatefulWidget {
  const BluetoothConnectionPage({super.key});

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
  bool _isConnecting = false;
  BluetoothDevice? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _checkBluetoothStatus();
    _requestPermissions();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
  }

  Future<void> _checkBluetoothStatus() async {
    // Get initial Bluetooth state using the recommended approach
    final state = await FlutterBluePlus.adapterState.first;
    setState(() {
      _isBluetoothEnabled = state == BluetoothAdapterState.on;
    });

    // Keep listening for state changes
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

    logger.i("Starting Bluetooth scan");

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        // Show all discovered devices without filtering
        _scanResults = results;

        // Log found devices for debugging
        if (results.isNotEmpty) {
          logger.i("Found ${results.length} Bluetooth devices");
        }
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
    Navigator.pop(context);
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
    });

    logger.i("Connecting to device: ${device.remoteId}");

    try {
      // Simulate connecting to device (in a real app, you would implement actual connection logic)
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _connectedDevice = device;
        _isConnecting = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully connected to ${device.platformName}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isConnecting = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
                // Connected device info (if connected)
                if (_connectedDevice != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.5),
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
                                'Connected to: ${_connectedDevice!.platformName.isNotEmpty ? _connectedDevice!.platformName : "Unknown Device"}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${_connectedDevice!.remoteId}',
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
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed:
                          _isBluetoothEnabled && !_isConnecting
                              ? (_isScanning ? _stopScanning : _startScanning)
                              : null,
                      child: Text(
                        _isScanning ? 'Stop Scan' : 'Scan for Devices',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Device list
                _isConnecting
                    ? const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Connecting to device...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    )
                    : _isScanning
                    ? const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Scanning for devices...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    )
                    : Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Available Devices',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _scanResults.isEmpty
                              ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    _isScanning
                                        ? 'Scanning for devices...'
                                        : 'No devices found. Try scanning again.',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                              : Expanded(
                                child: ListView.builder(
                                  itemCount: _scanResults.length,
                                  itemBuilder: (context, index) {
                                    final result = _scanResults[index];
                                    final device = result.device;
                                    final name =
                                        result
                                                .advertisementData
                                                .advName
                                                .isNotEmpty
                                            ? result.advertisementData.advName
                                            : device.platformName.isNotEmpty
                                            ? device.platformName
                                            : 'Unknown Device ${device.remoteId}';

                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 4.0,
                                      ),
                                      color: Colors.white.withOpacity(0.1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: Colors.white.withOpacity(0.2),
                                        ),
                                      ),
                                      child: ListTile(
                                        leading: const Icon(
                                          Icons.bluetooth,
                                          color: Colors.white,
                                        ),
                                        title: Text(
                                          name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Signal: ${result.rssi} dBm',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.7,
                                            ),
                                          ),
                                        ),
                                        trailing: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blueAccent,
                                            foregroundColor: Colors.white,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

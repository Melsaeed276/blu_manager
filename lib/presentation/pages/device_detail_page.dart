import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/bluetooth_device_entity.dart';
import '../viewmodels/device_detail_viewmodel.dart';
import '../widgets/connection_status_card.dart';
import '../widgets/file_transfer_section.dart';
import '../widgets/bluetooth_audio_player.dart';
import '../widgets/error_snackbar.dart';

class DeviceDetailPage extends ConsumerStatefulWidget {
  final BluetoothDeviceEntity device;

  const DeviceDetailPage({super.key, required this.device});

  @override
  ConsumerState<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends ConsumerState<DeviceDetailPage> {
  bool _isConnecting = false;
  bool _isConnected = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    // Auto-connect when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectToDevice();
    });
  }

  Future<void> _connectToDevice() async {
    if (_isConnecting || _isConnected) return;

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      final connectFunction = ref.read(connectToDeviceActionProvider(widget.device));
      await connectFunction();

      setState(() {
        _isConnecting = false;
        _isConnected = true;
        _successMessage = 'Connected successfully';
      });

      _showSuccessMessage('Connected successfully');
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMessage = e.toString();
      });

      _showErrorMessage(e.toString());
    }
  }

  Future<void> _disconnectFromDevice() async {
    if (!_isConnected) return;
    // Get action functions
    try {
      final disconnectFunction = ref.read(disconnectFromDeviceActionProvider(widget.device));
      await disconnectFunction();

      setState(() {
        _isConnected = false;
        _successMessage = 'Disconnected successfully';
      });

      _showSuccessMessage('Disconnected successfully');
    } catch (e) {
      _showErrorMessage(e.toString());
    }
  }

  Future<void> _sendFile() async {
    if (!_isConnected) {
      _showErrorMessage('Device is not connected');
      return;
    }

    try {
      final sendFileFunction = ref.read(sendFileActionProvider(widget.device));
      await sendFileFunction();
      _showSuccessMessage('File sent successfully');
    } catch (e) {
      _showErrorMessage(e.toString());
    }
  }

  Future<void> _receiveFile(String fileName) async {
    if (!_isConnected) {
      _showErrorMessage('Device is not connected');
      return;
    }

    try {
      final receiveFileFunction = ref.read(receiveFileActionProvider(widget.device));
      await receiveFileFunction(fileName);
      _showSuccessMessage('File receive started');
    } catch (e) {
      _showErrorMessage(e.toString());
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      ErrorSnackBar(message: message),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
            backgroundColor: Colors.green,
  @override
  Widget build(BuildContext context) {
          ),
        );
        clearMessages();
      }
          if (_isConnected)

    return Scaffold(
              onPressed: _disconnectFromDevice,
        title: Text(widget.device.name),
        actions: [
          else if (_isConnecting)
            IconButton(
              icon: const Icon(Icons.bluetooth_disabled),
              onPressed: disconnectFromDevice,
              tooltip: 'Disconnect',
            )
          else if (deviceState.isConnecting)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
              onPressed: _connectToDevice,
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.bluetooth_connected),
              onPressed: connectToDevice,
              tooltip: 'Connect',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getDeviceTypeIcon(widget.device.deviceType),
                          color: _getDeviceTypeColor(widget.device.deviceType),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Device Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getDeviceTypeColor(widget.device.deviceType),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getDeviceTypeLabel(widget.device.deviceType),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Device Type', _getDeviceTypeLabel(widget.device.deviceType)),
                    _buildInfoRow('Device ID', widget.device.id),
                    _buildInfoRow('Name', widget.device.name),
                    _buildInfoRow('Signal Strength', '${widget.device.rssi} dBm'),
                  ],
                ),
              ),
              connectionState: _isConnected
                  ? BluetoothConnectionState.connected
                  : BluetoothConnectionState.disconnected,
              isConnecting: _isConnecting,
              onConnect: _connectToDevice,
              onDisconnect: _disconnectFromDevice,
            // Connection Status Card
            ConnectionStatusCard(
              connectionState: deviceState.connectionState,
              isConnecting: deviceState.isConnecting,
              onConnect: connectToDevice,
            if (_isConnected)
            ),
                onSendFile: _sendFile,
                onReceiveFile: _receiveFile,
                transfers: const [], // Empty for now
            // File Transfer Section
            if (deviceState.isConnected)
              FileTransferSection(
                onSendFile: sendFile,
                onReceiveFile: receiveFile,
                transfers: deviceState.transfers,
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.bluetooth_disabled,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Connect to device to transfer files',
                        style: TextStyle(
                        onPressed: _isConnecting ? null : _connectToDevice,
                        icon: _isConnecting
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: deviceState.isConnecting ? null : connectToDevice,
                        icon: deviceState.isConnecting
                            ? const SizedBox(
                          _isConnecting ? 'Connecting...' : 'Connect to Device',
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.bluetooth_connected),
                        label: Text(
                          deviceState.isConnecting ? 'Connecting...' : 'Connect to Device',
                        ),
                      ),
                    ],
                  ),
            if (_isConnected)
              ),

            const SizedBox(height: 16),

            // Bluetooth Audio Player (for speakers, headphones, earbuds)
            if (deviceState.isConnected)
              BluetoothAudioPlayer(device: widget.device),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDeviceTypeIcon(BluetoothDeviceType deviceType) {
    switch (deviceType) {
      case BluetoothDeviceType.computer:
        return Icons.computer;
      case BluetoothDeviceType.phone:
        return Icons.smartphone;
      case BluetoothDeviceType.tablet:
        return Icons.tablet;
      case BluetoothDeviceType.speaker:
        return Icons.speaker;
      case BluetoothDeviceType.headphones:
        return Icons.headphones;
      case BluetoothDeviceType.earbuds:
        return Icons.earbuds;
      case BluetoothDeviceType.smartwatch:
        return Icons.watch;
      case BluetoothDeviceType.keyboard:
        return Icons.keyboard;
      case BluetoothDeviceType.mouse:
        return Icons.mouse;
      case BluetoothDeviceType.gameController:
        return Icons.sports_esports;
      case BluetoothDeviceType.printer:
        return Icons.print;
      case BluetoothDeviceType.camera:
        return Icons.camera_alt;
      case BluetoothDeviceType.car:
        return Icons.directions_car;
      case BluetoothDeviceType.tv:
        return Icons.tv;
      case BluetoothDeviceType.healthDevice:
        return Icons.health_and_safety;
      case BluetoothDeviceType.unknown:
      return Icons.bluetooth;
    }
  }

  Color _getDeviceTypeColor(BluetoothDeviceType deviceType) {
    switch (deviceType) {
      case BluetoothDeviceType.computer:
        return Colors.blue;
      case BluetoothDeviceType.phone:
      case BluetoothDeviceType.tablet:
        return Colors.purple;
      case BluetoothDeviceType.speaker:
      case BluetoothDeviceType.headphones:
      case BluetoothDeviceType.earbuds:
        return Colors.deepOrange;
      case BluetoothDeviceType.smartwatch:
        return Colors.teal;
      case BluetoothDeviceType.keyboard:
      case BluetoothDeviceType.mouse:
        return Colors.brown;
      case BluetoothDeviceType.gameController:
        return Colors.red;
      case BluetoothDeviceType.printer:
        return Colors.grey;
      case BluetoothDeviceType.camera:
        return Colors.indigo;
      case BluetoothDeviceType.car:
        return Colors.green;
      case BluetoothDeviceType.tv:
        return Colors.deepPurple;
      case BluetoothDeviceType.healthDevice:
        return Colors.pink;
      case BluetoothDeviceType.unknown:
      return Colors.grey;
    }
  }

  String _getDeviceTypeLabel(BluetoothDeviceType deviceType) {
    switch (deviceType) {
      case BluetoothDeviceType.computer:
        return 'Computer';
      case BluetoothDeviceType.phone:
        return 'Phone';
      case BluetoothDeviceType.tablet:
        return 'Tablet';
      case BluetoothDeviceType.speaker:
        return 'Speaker';
      case BluetoothDeviceType.headphones:
        return 'Headphones';
      case BluetoothDeviceType.earbuds:
        return 'Earbuds';
      case BluetoothDeviceType.smartwatch:
        return 'Watch';
      case BluetoothDeviceType.keyboard:
        return 'Keyboard';
      case BluetoothDeviceType.mouse:
        return 'Mouse';
      case BluetoothDeviceType.gameController:
        return 'Controller';
      case BluetoothDeviceType.printer:
        return 'Printer';
      case BluetoothDeviceType.camera:
        return 'Camera';
      case BluetoothDeviceType.car:
        return 'Car';
      case BluetoothDeviceType.tv:
        return 'TV';
      case BluetoothDeviceType.healthDevice:
        return 'Health';
      case BluetoothDeviceType.unknown:
      return 'Unknown';
    }
  }
}

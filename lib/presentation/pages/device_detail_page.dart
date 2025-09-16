import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/bluetooth_device_entity.dart';
import '../viewmodels/device_detail_viewmodel.dart';
import '../widgets/connection_status_card.dart';
import '../widgets/file_transfer_section.dart';
import '../widgets/bluetooth_audio_player.dart';

class DeviceDetailPage extends ConsumerStatefulWidget {
  final BluetoothDeviceEntity device;

  const DeviceDetailPage({super.key, required this.device});

  @override
  ConsumerState<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends ConsumerState<DeviceDetailPage> {
  DeviceDetailState? currentState;

  @override
  void initState() {
    super.initState();
    // Initialize state
    currentState = DeviceDetailState(device: widget.device);

    // Auto-connect when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectToDevice();
    });
  }

  Future<void> _connectToDevice() async {
    if (currentState == null) return;

    final controller = ref.read(deviceDetailControllerProvider(widget.device));
    final newState = await controller.connectToDevice(currentState!);
    setState(() {
      currentState = newState;
    });

    _handleStateMessages(newState);
  }

  Future<void> _disconnectFromDevice() async {
    if (currentState == null) return;

    final controller = ref.read(deviceDetailControllerProvider(widget.device));
    final newState = await controller.disconnectFromDevice(currentState!);
    setState(() {
      currentState = newState;
    });

    _handleStateMessages(newState);
  }

  Future<void> _sendFile() async {
    if (currentState == null) return;

    final controller = ref.read(deviceDetailControllerProvider(widget.device));
    final newState = await controller.sendFile(currentState!);
    setState(() {
      currentState = newState;
    });

    _handleStateMessages(newState);
  }

  Future<void> _receiveFile(String fileName) async {
    if (currentState == null) return;

    final controller = ref.read(deviceDetailControllerProvider(widget.device));
    final newState = await controller.receiveFile(currentState!, fileName);
    setState(() {
      currentState = newState;
    });

    _handleStateMessages(newState);
  }

  void _handleStateMessages(DeviceDetailState state) {
    if (state.errorMessage != null) {
      _showErrorMessage(state.errorMessage!);
      _clearMessages();
    }
    if (state.successMessage != null) {
      _showSuccessMessage(state.successMessage!);
      _clearMessages();
    }
  }

  void _clearMessages() {
    if (currentState == null) return;

    final controller = ref.read(deviceDetailControllerProvider(widget.device));
    final newState = controller.clearMessages(currentState!);
    setState(() {
      currentState = newState;
    });
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentState == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final state = currentState!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name.isNotEmpty ? widget.device.name : 'Unknown Device'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Status Card
            ConnectionStatusCard(
              connectionState: state.connectionState,
              isConnecting: state.isConnecting,
              onConnect: _connectToDevice,
              onDisconnect: _disconnectFromDevice,
            ),
            
            const SizedBox(height: 16),
            
            // File Transfer Section
            if (state.isConnected) ...[
              FileTransferSection(
                onSendFile: _sendFile,
                onReceiveFile: _receiveFile,
                transfers: state.transfers,
              ),
              
              const SizedBox(height: 16),
              
              // Bluetooth Audio Player (if device supports audio)
              BluetoothAudioPlayer(device: widget.device),
            ],
            
            // Device Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device Information',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Name: ${widget.device.name.isNotEmpty ? widget.device.name : 'Unknown'}'),
                    Text('ID: ${widget.device.id}'),
                    Text('Type: ${widget.device.deviceType.toString().split('.').last}'),
                    Text('RSSI: ${widget.device.rssi} dBm'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

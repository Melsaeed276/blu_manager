import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/bluetooth_device_entity.dart';
import '../viewmodels/device_detail_viewmodel.dart';
import '../widgets/connection_status_card.dart';
import '../widgets/file_transfer_section.dart';

class DeviceDetailPage extends ConsumerStatefulWidget {
  final BluetoothDeviceEntity device;

  const DeviceDetailPage({super.key, required this.device});

  @override
  ConsumerState<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends ConsumerState<DeviceDetailPage> {
  @override
  void initState() {
    super.initState();
    // Initialize device and auto-connect when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deviceDetailNotifierProvider.notifier).setDevice(widget.device);
      //ref.read(deviceDetailNotifierProvider.notifier).connectToDevice();
    });
  }

  void _showErrorDialog(String message) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (mounted) {
      ref.read(deviceDetailNotifierProvider.notifier).clearMessages();
    }
  }

  Future<void> _connectToDevice() async {
    ref.read(deviceDetailNotifierProvider.notifier).connectToDevice();
  }

  Future<void> _disconnectFromDevice() async {
    ref.read(deviceDetailNotifierProvider.notifier).disconnectFromDevice();
  }

  Future<void> _sendFile() async {
    ref.read(deviceDetailNotifierProvider.notifier).sendFile();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for messages (must be inside build per Riverpod rules)
    ref.listen<DeviceDetailState>(deviceDetailNotifierProvider, (previous, next) {
      if (!mounted) return;
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showErrorDialog(next.errorMessage!);
        });
      } else if (next.successMessage != null && next.successMessage != previous?.successMessage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.successMessage!)),
          );
          ref.read(deviceDetailNotifierProvider.notifier).clearMessages();
        });
      }
    });

    final state = ref.watch(deviceDetailNotifierProvider);

    // Show loading while device is being initialized
    if (state.device.id.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.device.name.isNotEmpty ? widget.device.name : 'Unknown Device',
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConnectionStatusCard(
              connectionState: state.connectionState,
              isConnecting: state.isConnecting,
              onConnect: _connectToDevice,
              onDisconnect: _disconnectFromDevice,
            ),
            const SizedBox(height: 16),
            if (state.isConnected) ...[
              FileTransferSection(
                onSendFile: _sendFile,
                transfers: state.transfers,
              ),
              const SizedBox(height: 16),
            ],
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
                    Text(
                      'Name: ${widget.device.name.isNotEmpty ? widget.device.name : 'Unknown'}',
                    ),
                    Text('ID: ${widget.device.id}'),
                    Text(
                      'Type: ${widget.device.deviceType.toString().split('.').last}',
                    ),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/viewmodel_providers.dart';
import '../widgets/bluetooth_device_card.dart';
import '../widgets/error_dialog.dart';
import 'device_detail_page.dart';

class BluetoothDevicesPage extends ConsumerStatefulWidget {
  const BluetoothDevicesPage({super.key});

  @override
  ConsumerState<BluetoothDevicesPage> createState() => _BluetoothDevicesPageState();
}

class _BluetoothDevicesPageState extends ConsumerState<BluetoothDevicesPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(bluetoothScanViewModelProvider);
    final scanViewModel = ref.read(bluetoothScanViewModelProvider.notifier);

    // Show error dialog if there's an error
    if (scanState.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => ErrorDialog(
            message: scanState.errorMessage!,
            onDismiss: () => scanViewModel.clearError(),
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Devices'),
        actions: [
          if (scanState.isScanning)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: scanViewModel.startScanning,
            ),
        ],
      ),
      body: Column(
        children: [
          // Bluetooth Status Banner
          if (!scanState.isBluetoothEnabled)
            Container(
              width: double.infinity,
              color: Colors.red.shade100,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.bluetooth_disabled, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bluetooth is disabled. Please enable Bluetooth to scan for devices.',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),

          // Device List
          Expanded(
            child: RefreshIndicator(
              onRefresh: scanViewModel.startScanning,
              child: scanState.devices.isEmpty
                  ? _buildEmptyState(scanState.isScanning)
                  : ListView.builder(
                      itemCount: scanState.devices.length,
                      itemBuilder: (context, index) {
                        final device = scanState.devices[index];
                        return BluetoothDeviceCard(
                          device: device,
                          onTap: () => _navigateToDeviceDetail(device),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: scanState.isScanning ? null : scanViewModel.startScanning,
        tooltip: 'Scan for devices',
        child: scanState.isScanning
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.bluetooth_searching),
      ),
    );
  }

  Widget _buildEmptyState(bool isScanning) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isScanning ? Icons.bluetooth_searching : Icons.bluetooth,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            isScanning
                ? 'Scanning for devices...'
                : 'No devices found.\nTap the scan button to start searching.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          if (!isScanning) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref
                  .read(bluetoothScanViewModelProvider.notifier)
                  .startScanning(),
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('Start Scanning'),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToDeviceDetail(device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceDetailPage(device: device),
      ),
    );
  }
}

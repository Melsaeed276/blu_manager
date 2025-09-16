import 'package:flutter/material.dart';
import '../../domain/entities/bluetooth_device_entity.dart';

class BluetoothDeviceCard extends StatelessWidget {
  final BluetoothDeviceEntity device;
  final VoidCallback onTap;

  const BluetoothDeviceCard({
    super.key,
    required this.device,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getSignalColor(),
          child: Icon(
            _getDeviceTypeIcon(),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device.id),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.signal_cellular_alt,
                  size: 14,
                  color: _getSignalColor(),
                ),
                const SizedBox(width: 4),
                Text(
                  '${device.rssi} dBm',
                  style: TextStyle(
                    color: _getSignalColor(),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getDeviceTypeColor(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getDeviceTypeLabel(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (device.isConnected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Connected',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Color _getSignalColor() {
    if (device.rssi > -60) return Colors.green;
    if (device.rssi > -80) return Colors.orange;
    return Colors.red;
  }

  IconData _getDeviceTypeIcon() {
    switch (device.deviceType) {
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
      return device.isConnected ? Icons.bluetooth_connected : Icons.bluetooth;
    }
  }

  Color _getDeviceTypeColor() {
    switch (device.deviceType) {
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

  String _getDeviceTypeLabel() {
    switch (device.deviceType) {
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

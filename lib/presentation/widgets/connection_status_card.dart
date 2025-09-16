import 'package:flutter/material.dart';
import '../../domain/entities/bluetooth_device_entity.dart';

class ConnectionStatusCard extends StatelessWidget {
  final BluetoothConnectionState connectionState;
  final bool isConnecting;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const ConnectionStatusCard({
    super.key,
    required this.connectionState,
    required this.isConnecting,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connection Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatusIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusText(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _getStatusDescription(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildActionButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (isConnecting) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    IconData icon;
    Color color;

    switch (connectionState) {
      case BluetoothConnectionState.connected:
        icon = Icons.bluetooth_connected;
        color = Colors.green;
        break;
      case BluetoothConnectionState.disconnected:
        icon = Icons.bluetooth;
        color = Colors.grey;
        break;
    }

    return Icon(icon, color: color, size: 24);
  }

  String _getStatusText() {
    if (isConnecting) return 'Connecting...';

    switch (connectionState) {
      case BluetoothConnectionState.connected:
        return 'Connected';
      case BluetoothConnectionState.disconnected:
        return 'Disconnected';
    }
  }

  String _getStatusDescription() {
    if (isConnecting) return 'Establishing connection to device';

    switch (connectionState) {
      case BluetoothConnectionState.connected:
        return 'Ready for file transfer';
      case BluetoothConnectionState.disconnected:
        return 'Tap connect to establish connection';
    }
  }

  Widget _buildActionButton() {
    final isConnected = connectionState == BluetoothConnectionState.connected;
    final canInteract = !isConnecting;

    return ElevatedButton.icon(
      onPressed: canInteract ? (isConnected ? onDisconnect : onConnect) : null,
      icon: Icon(isConnected ? Icons.bluetooth_disabled : Icons.bluetooth_connected),
      label: Text(isConnected ? 'Disconnect' : 'Connect'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isConnected ? Colors.red : Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}

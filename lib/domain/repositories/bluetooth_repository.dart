import '../entities/bluetooth_device_entity.dart';

abstract class BluetoothRepository {
  Future<bool> isBluetoothEnabled();
  Stream<List<BluetoothDeviceEntity>> scanForDevices();
  Future<void> startScan();
  Future<void> stopScan();
  Future<bool> connectToDevice(String deviceId);
  Future<void> disconnectFromDevice(String deviceId);
  Stream<BluetoothConnectionState> getConnectionState(String deviceId);
  Future<List<String>> getConnectedDevices();
}

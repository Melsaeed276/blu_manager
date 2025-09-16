import '../../domain/entities/bluetooth_device_entity.dart';
import '../../domain/repositories/bluetooth_repository.dart';
import '../datasources/bluetooth_datasource.dart';

class BluetoothRepositoryImpl implements BluetoothRepository {
  final BluetoothDataSource dataSource;

  BluetoothRepositoryImpl({required this.dataSource});

  @override
  Future<bool> isBluetoothEnabled() {
    return dataSource.isBluetoothEnabled();
  }

  @override
  Stream<List<BluetoothDeviceEntity>> scanForDevices() {
    return dataSource.scanForDevices();
  }

  @override
  Future<void> startScan() {
    return dataSource.startScan();
  }

  @override
  Future<void> stopScan() {
    return dataSource.stopScan();
  }

  @override
  Future<bool> connectToDevice(String deviceId) {
    return dataSource.connectToDevice(deviceId);
  }

  @override
  Future<void> disconnectFromDevice(String deviceId) {
    return dataSource.disconnectFromDevice(deviceId);
  }

  @override
  Stream<BluetoothConnectionState> getConnectionState(String deviceId) {
    return dataSource.getConnectionState(deviceId);
  }

  @override
  Future<List<String>> getConnectedDevices() {
    return dataSource.getConnectedDevices();
  }
}

import '../entities/bluetooth_device_entity.dart';
import '../repositories/bluetooth_repository.dart';
import '../../core/usecases/usecase.dart';

class ScanForDevices extends StreamUseCase<List<BluetoothDeviceEntity>, NoParams> {
  final BluetoothRepository repository;

  ScanForDevices(this.repository);

  @override
  Stream<List<BluetoothDeviceEntity>> call(NoParams params) {
    return repository.scanForDevices();
  }
}

class StartScan extends UseCase<void, NoParams> {
  final BluetoothRepository repository;

  StartScan(this.repository);

  @override
  Future<void> call(NoParams params) {
    return repository.startScan();
  }
}

class StopScan extends UseCase<void, NoParams> {
  final BluetoothRepository repository;

  StopScan(this.repository);

  @override
  Future<void> call(NoParams params) {
    return repository.stopScan();
  }
}

class ConnectToDevice extends UseCase<bool, ConnectToDeviceParams> {
  final BluetoothRepository repository;

  ConnectToDevice(this.repository);

  @override
  Future<bool> call(ConnectToDeviceParams params) {
    return repository.connectToDevice(params.deviceId);
  }
}

class DisconnectFromDevice extends UseCase<void, DisconnectFromDeviceParams> {
  final BluetoothRepository repository;

  DisconnectFromDevice(this.repository);

  @override
  Future<void> call(DisconnectFromDeviceParams params) {
    return repository.disconnectFromDevice(params.deviceId);
  }
}

class GetConnectionState extends StreamUseCase<BluetoothConnectionState, GetConnectionStateParams> {
  final BluetoothRepository repository;

  GetConnectionState(this.repository);

  @override
  Stream<BluetoothConnectionState> call(GetConnectionStateParams params) {
    return repository.getConnectionState(params.deviceId);
  }
}

class CheckBluetoothEnabled extends UseCase<bool, NoParams> {
  final BluetoothRepository repository;

  CheckBluetoothEnabled(this.repository);

  @override
  Future<bool> call(NoParams params) {
    return repository.isBluetoothEnabled();
  }
}

// Parameter classes
class ConnectToDeviceParams {
  final String deviceId;
  ConnectToDeviceParams({required this.deviceId});
}

class DisconnectFromDeviceParams {
  final String deviceId;
  DisconnectFromDeviceParams({required this.deviceId});
}

class GetConnectionStateParams {
  final String deviceId;
  GetConnectionStateParams({required this.deviceId});
}

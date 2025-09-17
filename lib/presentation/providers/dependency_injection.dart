import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/bluetooth_datasource.dart';
import '../../data/datasources/file_transfer_datasource.dart';
import '../../data/repositories/bluetooth_repository_impl.dart';
import '../../data/repositories/file_transfer_repository_impl.dart';
import '../../data/repositories/audio_stream_repository_impl.dart';
import '../../domain/repositories/bluetooth_repository.dart';
import '../../domain/repositories/file_transfer_repository.dart';
import '../../domain/repositories/audio_stream_repository.dart';
import '../../domain/usecases/bluetooth_usecases.dart';
import '../../domain/usecases/file_transfer_usecases.dart';
import '../../domain/usecases/audio_stream_usecases.dart';

// Data Sources
final bluetoothDataSourceProvider = Provider<BluetoothDataSource>((ref) {
  return BluetoothDataSourceImpl();
});

final fileTransferDataSourceProvider = Provider<FileTransferDataSource>((ref) {
  return FileTransferDataSourceImpl();
});


// Repositories
final bluetoothRepositoryProvider = Provider<BluetoothRepository>((ref) {
  return BluetoothRepositoryImpl(
    dataSource: ref.read(bluetoothDataSourceProvider),
  );
});

final fileTransferRepositoryProvider = Provider<FileTransferRepository>((ref) {
  return FileTransferRepositoryImpl(
    dataSource: ref.read(fileTransferDataSourceProvider),
  );
});


// Bluetooth Use Cases
final scanForDevicesProvider = Provider<ScanForDevices>((ref) {
  return ScanForDevices(ref.read(bluetoothRepositoryProvider));
});

final startScanProvider = Provider<StartScan>((ref) {
  return StartScan(ref.read(bluetoothRepositoryProvider));
});

final stopScanProvider = Provider<StopScan>((ref) {
  return StopScan(ref.read(bluetoothRepositoryProvider));
});

final connectToDeviceProvider = Provider<ConnectToDevice>((ref) {
  return ConnectToDevice(ref.read(bluetoothRepositoryProvider));
});

final disconnectFromDeviceProvider = Provider<DisconnectFromDevice>((ref) {
  return DisconnectFromDevice(ref.read(bluetoothRepositoryProvider));
});

final getConnectionStateProvider = Provider<GetConnectionState>((ref) {
  return GetConnectionState(ref.read(bluetoothRepositoryProvider));
});

final checkBluetoothEnabledProvider = Provider<CheckBluetoothEnabled>((ref) {
  return CheckBluetoothEnabled(ref.read(bluetoothRepositoryProvider));
});

// File Transfer Use Cases
final sendFileProvider = Provider<SendFile>((ref) {
  return SendFile(ref.read(fileTransferRepositoryProvider));
});

final pickFileProvider = Provider<PickFile>((ref) {
  return PickFile(ref.read(fileTransferRepositoryProvider));
});

final getTransferProgressProvider = Provider<GetTransferProgress>((ref) {
  return GetTransferProgress(ref.read(fileTransferRepositoryProvider));
});

final getTransferHistoryProvider = Provider<GetTransferHistory>((ref) {
  return GetTransferHistory(ref.read(fileTransferRepositoryProvider));
});

final cancelTransferProvider = Provider<CancelTransfer>((ref) {
  return CancelTransfer(ref.read(fileTransferRepositoryProvider));
});




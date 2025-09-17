import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/bluetooth_scan_viewmodel.dart';

// Bluetooth Scan ViewModel Provider
final bluetoothScanViewModelProvider =
    NotifierProvider<BluetoothScanViewModel, BluetoothScanState>(() {
  return BluetoothScanViewModel();
});

// Device Detail ViewModel Provider Factory - now correctly implemented
// Use the factory function from device_detail_viewmodel.dart
// This provider is already defined in device_detail_viewmodel.dart


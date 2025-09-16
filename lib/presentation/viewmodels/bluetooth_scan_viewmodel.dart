import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/bluetooth_device_entity.dart';
import '../../core/usecases/usecase.dart';
import '../providers/dependency_injection.dart';

// State for Bluetooth scanning
class BluetoothScanState {
  final List<BluetoothDeviceEntity> devices;
  final bool isScanning;
  final bool isBluetoothEnabled;
  final String? errorMessage;

  const BluetoothScanState({
    this.devices = const [],
    this.isScanning = false,
    this.isBluetoothEnabled = true,
    this.errorMessage,
  });

  BluetoothScanState copyWith({
    List<BluetoothDeviceEntity>? devices,
    bool? isScanning,
    bool? isBluetoothEnabled,
    String? errorMessage,
  }) {
    return BluetoothScanState(
      devices: devices ?? this.devices,
      isScanning: isScanning ?? this.isScanning,
      isBluetoothEnabled: isBluetoothEnabled ?? this.isBluetoothEnabled,
      errorMessage: errorMessage,
    );
  }
}

// ViewModel for Bluetooth scanning
class BluetoothScanViewModel extends Notifier<BluetoothScanState> {
  @override
  BluetoothScanState build() {
    // Initialize the stream listener
    _initializeStreamListener();
    return const BluetoothScanState();
  }

  void _initializeStreamListener() {
    // Listen to scan results
    ref.read(scanForDevicesProvider).call(const NoParams()).listen(
      (devices) {
        state = state.copyWith(devices: devices, errorMessage: null);
      },
      onError: (error) {
        state = state.copyWith(
          errorMessage: error.toString(),
          isScanning: false,
        );
      },
    );
  }

  Future<void> checkBluetoothStatus() async {
    try {
      final isEnabled = await ref.read(checkBluetoothEnabledProvider).call(const NoParams());
      state = state.copyWith(
        isBluetoothEnabled: isEnabled,
        errorMessage: isEnabled ? null : 'Bluetooth is disabled',
      );
    } catch (e) {
      state = state.copyWith(
        isBluetoothEnabled: false,
        errorMessage: 'Failed to check Bluetooth status',
      );
    }
  }

  Future<void> startScanning() async {
    if (state.isScanning) return;

    try {
      await checkBluetoothStatus();

      if (!state.isBluetoothEnabled) {
        state = state.copyWith(errorMessage: 'Please enable Bluetooth to scan for devices');
        return;
      }

      state = state.copyWith(isScanning: true, errorMessage: null);
      await ref.read(startScanProvider).call(const NoParams());

      // Stop scanning after 10 seconds
      Future.delayed(const Duration(seconds: 10), () {
        if (state.isScanning) {
          stopScanning();
        }
      });
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: 'Failed to start scanning: ${e.toString()}',
      );
    }
  }

  Future<void> stopScanning() async {
    try {
      await ref.read(stopScanProvider).call(const NoParams());
      state = state.copyWith(isScanning: false);
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: 'Failed to stop scanning: ${e.toString()}',
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

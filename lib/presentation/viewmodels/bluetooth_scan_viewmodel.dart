import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/bluetooth_device_entity.dart';
import '../../core/usecases/usecase.dart';
import '../providers/dependency_injection.dart';

// State for Bluetooth scanning
class BluetoothScanState {
  final List<BluetoothDeviceEntity> devices;
  final List<BluetoothDeviceEntity> displayedDevices; // after search/filter/sort
  final bool isScanning;
  final bool isBluetoothEnabled;
  final String? errorMessage;
  final String searchQuery;
  final DeviceFilter filter;
  final DeviceSort sort;

  const BluetoothScanState({
    this.devices = const [],
    this.displayedDevices = const [],
    this.isScanning = false,
    this.isBluetoothEnabled = true,
    this.errorMessage,
    this.searchQuery = '',
    this.filter = DeviceFilter.all,
    this.sort = DeviceSort.none,
  });

  BluetoothScanState copyWith({
    List<BluetoothDeviceEntity>? devices,
    List<BluetoothDeviceEntity>? displayedDevices,
    bool? isScanning,
    bool? isBluetoothEnabled,
    String? errorMessage,
    String? searchQuery,
    DeviceFilter? filter,
    DeviceSort? sort,
  }) {
    return BluetoothScanState(
      devices: devices ?? this.devices,
      displayedDevices: displayedDevices ?? this.displayedDevices,
      isScanning: isScanning ?? this.isScanning,
      isBluetoothEnabled: isBluetoothEnabled ?? this.isBluetoothEnabled,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
    );
  }
}

enum DeviceFilter { all, knownName, connected, disconnected }
enum DeviceSort { none, nearestRssi, nameAsc }

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
        _recomputeDisplayedDevices();
      },
      onError: (error) {
        state = state.copyWith(
          errorMessage: error.toString(),
          isScanning: false,
        );
      },
    );
  }

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
    _recomputeDisplayedDevices();
  }

  void updateFilter(DeviceFilter filter) {
    state = state.copyWith(filter: filter);
    _recomputeDisplayedDevices();
  }

  void updateSort(DeviceSort sort) {
    state = state.copyWith(sort: sort);
    _recomputeDisplayedDevices();
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      filter: DeviceFilter.all,
      sort: DeviceSort.none,
    );
    _recomputeDisplayedDevices();
  }

  void _recomputeDisplayedDevices() {
    List<BluetoothDeviceEntity> list = List.of(state.devices);

    // Filter
    switch (state.filter) {
      case DeviceFilter.knownName:
        list = list.where((d) => d.deviceType != BluetoothDeviceType.unknown).toList();
        break;
      case DeviceFilter.connected:
        list = list.where((d) => d.isConnected || d.connectionState == BluetoothConnectionState.connected).toList();
        break;
      case DeviceFilter.disconnected:
        list = list.where((d) => !(d.isConnected || d.connectionState == BluetoothConnectionState.connected)).toList();
        break;
      case DeviceFilter.all:
        break;
    }

    // Search
    if (state.searchQuery.isNotEmpty) {
      final q = state.searchQuery.toLowerCase();
      list = list.where((d) => d.name.toLowerCase().contains(q)).toList();
    }

    // Sort
    switch (state.sort) {
      case DeviceSort.nearestRssi:
        list.sort((a, b) => b.rssi.compareTo(a.rssi)); // higher RSSI first
        break;
      case DeviceSort.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case DeviceSort.none:
        break;
    }

    state = state.copyWith(displayedDevices: list);
  }

  Future<void> startScanning() async {
    if (state.isScanning) return;

    try {
      await checkBluetoothStatus();

      if (!state.isBluetoothEnabled) {
        state = state.copyWith(
          errorMessage: 'Please enable Bluetooth to scan for devices',
        );
        return;
      }

      state = state.copyWith(isScanning: true, errorMessage: null);
      await ref.read(startScanProvider).call(const NoParams());

      // Stop scanning after 10 seconds
      Future.delayed(const Duration(seconds: 60), () {
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

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

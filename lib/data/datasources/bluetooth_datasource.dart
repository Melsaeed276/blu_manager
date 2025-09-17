import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../models/bluetooth_device_model.dart';
import '../../domain/entities/bluetooth_device_entity.dart';
import '../../core/utils/logger.dart';

abstract class BluetoothDataSource {
  Future<bool> isBluetoothEnabled();
  Stream<List<BluetoothDeviceModel>> scanForDevices();
  Future<void> startScan();
  Future<void> stopScan();
  Future<bool> connectToDevice(String deviceId);
  Future<void> disconnectFromDevice(String deviceId);
  Stream<BluetoothConnectionState> getConnectionState(String deviceId);
  Future<List<String>> getConnectedDevices();
}

class BluetoothDataSourceImpl implements BluetoothDataSource {
  final Map<String, fbp.BluetoothDevice> _cachedDevices = {};
  final StreamController<List<BluetoothDeviceModel>> _scanResultsController =
      StreamController<List<BluetoothDeviceModel>>.broadcast();

  List<BluetoothDeviceModel> _currentScanResults = [];
  Timer? _scanTimer;

  @override
  Future<bool> isBluetoothEnabled() async {
    try {
      final state = await fbp.FlutterBluePlus.adapterState.first;
      return state == fbp.BluetoothAdapterState.on;
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<List<BluetoothDeviceModel>> scanForDevices() {
    return _scanResultsController.stream;
  }

  @override
  Future<void> startScan() async {
    try {
      // Check if Bluetooth is enabled
      final isEnabled = await isBluetoothEnabled();
      if (!isEnabled) {
        throw Exception('Bluetooth is not enabled');
      }

      // Clear previous results
      _currentScanResults.clear();
      _scanResultsController.add(_currentScanResults);

      // First, add already connected devices to the list
      await _addConnectedDevices();

      // Start scanning with macOS-optimized settings
      await fbp.FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 30), // Longer timeout for macOS
        androidUsesFineLocation: true,
        // Scan for all services to catch more devices
        //withServices: [],
        // macOS-specific: Allow duplicates to catch name updates
        // allowDuplicates: Platform.isMacOS,
      );

      // Listen to scan results with enhanced processing
      fbp.FlutterBluePlus.scanResults.listen((results) {
        _processScanResults(results);
      });

      // On macOS, periodically refresh to catch name updates
      if (Platform.isMacOS) {
        _scanTimer = Timer.periodic(const Duration(seconds: 5), (_) {
          _refreshConnectedDevices();
        });
      }
    } catch (e) {
      throw Exception('Failed to start scan: $e');
    }
  }

  @override
  Future<void> stopScan() async {
    try {
      _scanTimer?.cancel();
      _scanTimer = null;

      if (fbp.FlutterBluePlus.isScanningNow) {
        await fbp.FlutterBluePlus.stopScan();
      }
    } catch (e) {
      throw Exception('Failed to stop scan: $e');
    }
  }

  @override
  Future<bool> connectToDevice(String deviceId) async {
    try {
      final device = _cachedDevices[deviceId];
      if (device == null) {
        throw Exception('Device not found');
      }

      await device.connect(timeout: const Duration(seconds: 15));

      // Update the device in our current results
      final deviceIndex = _currentScanResults.indexWhere(
        (d) => d.id == deviceId,
      );
      if (deviceIndex >= 0) {
        _currentScanResults[deviceIndex] = _currentScanResults[deviceIndex]
            .copyWith(
              isConnected: true,
              connectionState: BluetoothConnectionState.connected,
            );
        _scanResultsController.add(_currentScanResults);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> disconnectFromDevice(String deviceId) async {
    try {
      final device = _cachedDevices[deviceId];
      if (device != null) {
        await device.disconnect();

        // Update the device in our current results
        final deviceIndex = _currentScanResults.indexWhere(
          (d) => d.id == deviceId,
        );
        if (deviceIndex >= 0) {
          _currentScanResults[deviceIndex] = _currentScanResults[deviceIndex]
              .copyWith(
                isConnected: false,
                connectionState: BluetoothConnectionState.disconnected,
              );
          _scanResultsController.add(_currentScanResults);
        }
      }
    } catch (e) {
      throw Exception('Failed to disconnect: $e');
    }
  }

  @override
  Stream<BluetoothConnectionState> getConnectionState(String deviceId) {
    final device = _cachedDevices[deviceId];
    if (device == null) {
      return Stream.value(BluetoothConnectionState.disconnected);
    }

    return device.connectionState.map(
      (state) => BluetoothDeviceModel.mapConnectionState(state),
    );
  }

  @override
  Future<List<String>> getConnectedDevices() async {
    try {
      final connectedDevices = fbp.FlutterBluePlus.connectedDevices;
      return connectedDevices
          .map((device) => device.remoteId.toString())
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Enhanced scan result processing
  void _processScanResults(List<fbp.ScanResult> results) {
    final Map<String, BluetoothDeviceModel> merged = {
      for (final existing in _currentScanResults) existing.id: existing,
    };

    for (final result in results) {
      var fresh = BluetoothDeviceModel.fromScanResult(result);
      final existing = merged[fresh.id];

      if (existing != null) {
        final keepExistingName = existing.name.trim().isNotEmpty &&
            (fresh.name.trim().isEmpty || existing.name != existing.id);
        final newName = keepExistingName ? existing.name : fresh.name;

        final refinedType = (existing.deviceType == BluetoothDeviceType.unknown &&
                fresh.deviceType != BluetoothDeviceType.unknown)
            ? fresh.deviceType
            : existing.deviceType;

        final newRawName = existing.rawName.isEmpty && fresh.rawName.isNotEmpty
            ? fresh.rawName
            : existing.rawName;

        fresh = existing.copyWith(
          name: newName,
          rssi: fresh.rssi,
          deviceType: refinedType,
          rawName: newRawName,
        );
      }

      // Do not reclassify unknown; keep placeholder logic handled in model.
      merged[fresh.id] = fresh;
      _cachedDevices[fresh.id] = result.device; // cache
    }

    _currentScanResults = merged.values.toList();

    _currentScanResults.sort((a, b) {
      final aAudio = _isAudioDevice(a.deviceType);
      final bAudio = _isAudioDevice(b.deviceType);
      if (aAudio && !bAudio) return -1;
      if (!aAudio && bAudio) return 1;
      return b.rssi.compareTo(a.rssi);
    });

    _scanResultsController.add(_currentScanResults);
  }


  // Add already connected devices to improve discovery on macOS
  Future<void> _addConnectedDevices() async {
    try {
      final connectedDevices = fbp.FlutterBluePlus.connectedDevices;

      for (final device in connectedDevices) {
        // Try to get additional device info for connected devices
        final deviceModel = await _createEnhancedDeviceModel(
          device,
          isConnected: true,
        );

        final existingIndex = _currentScanResults.indexWhere(
          (d) => d.id == deviceModel.id,
        );
        if (existingIndex >= 0) {
          _currentScanResults[existingIndex] = deviceModel;
        } else {
          _currentScanResults.add(deviceModel);
        }

        _cachedDevices[deviceModel.id] = device;
      }

      _scanResultsController.add(_currentScanResults);
    } catch (e, st) {
      AppLogger.error('Error adding connected devices', error: e, stackTrace: st);
    }
  }

  // Enhanced device model creation with additional info gathering
  Future<BluetoothDeviceModel> _createEnhancedDeviceModel(
    fbp.BluetoothDevice device, {
    bool isConnected = false,
    int rssi = 0,
  }) async {
    String deviceName = device.platformName;
    final originalRaw = deviceName; // preserve raw platform name
    BluetoothDeviceType deviceType = BluetoothDeviceType.unknown;

    if (isConnected) {
      try {
        final services = await device.discoverServices().timeout(
          const Duration(seconds: 5),
          onTimeout: () => <fbp.BluetoothService>[],
        );

        deviceType = _detectDeviceTypeFromServices(services, deviceName);

        if (deviceName.isEmpty) {
          deviceName = await _tryGetDeviceNameFromServices(services) ?? deviceName;
        }
      } catch (e, st) {
        AppLogger.warn('Error discovering device info for connected device ${device.remoteId}', error: e, stackTrace: st);
      }
    }

    if (deviceType == BluetoothDeviceType.unknown) {
      deviceName = ''; // force placeholder downstream consistency
    }
    if (deviceName.isEmpty) {
      deviceName = 'Bluetooth Device';
    }

    return BluetoothDeviceModel(
      id: device.remoteId.toString(),
      name: deviceName,
      rawName: originalRaw,
      rssi: rssi,
      isConnected: isConnected,
      connectionState: isConnected
          ? BluetoothConnectionState.connected
          : BluetoothConnectionState.disconnected,
      deviceType: deviceType,
    );
  }

  // Detect device type from discovered services
  BluetoothDeviceType _detectDeviceTypeFromServices(
    List<fbp.BluetoothService> services,
    String deviceName,
  ) {
    final deviceNameLower = deviceName.toLowerCase();

    for (final service in services) {
      final serviceUuid = service.serviceUuid.toString().toLowerCase();

      // Audio services
      if (serviceUuid.contains('110b') ||
          serviceUuid.contains('110a') ||
          serviceUuid.contains('110d') ||
          serviceUuid.contains('111e') ||
          serviceUuid.contains('1108')) {
        if (deviceNameLower.contains('speaker') ||
            deviceNameLower.contains('boom')) {
          return BluetoothDeviceType.speaker;
        } else if (deviceNameLower.contains('airpods') ||
            deviceNameLower.contains('earbuds')) {
          return BluetoothDeviceType.earbuds;
        } else if (deviceNameLower.contains('headphones') ||
            deviceNameLower.contains('headset')) {
          return BluetoothDeviceType.headphones;
        } else {
          return BluetoothDeviceType.speaker; // Default for audio devices
        }
      }

      // HID service
      if (serviceUuid.contains('1812')) {
        if (deviceNameLower.contains('mouse')) return BluetoothDeviceType.mouse;
        if (deviceNameLower.contains('keyboard')) {
          return BluetoothDeviceType.keyboard;
        }
        return BluetoothDeviceType.mouse; // Default for HID
      }
    }

    return BluetoothDeviceType.unknown;
  }

  // Try to get device name from Generic Access Service
  Future<String?> _tryGetDeviceNameFromServices(
    List<fbp.BluetoothService> services,
  ) async {
    try {
      // Look for Generic Access Service (0x1800)
      final gasService = services
          .where((s) => s.serviceUuid.toString().toLowerCase().contains('1800'))
          .firstOrNull;

      if (gasService != null) {
        final characteristics = gasService.characteristics; // Remove await here

        // Look for Device Name characteristic (0x2A00)
        final nameCharacteristic = characteristics
            .where(
              (c) => c.characteristicUuid.toString().toLowerCase().contains(
                '2a00',
              ),
            )
            .firstOrNull;

        if (nameCharacteristic != null) {
          final value = await nameCharacteristic.read();
          return String.fromCharCodes(value);
        }
      }
    } catch (e, st) {
      AppLogger.warn('Error reading device name from services', error: e, stackTrace: st);
    }
    return null;
  }

  // Refresh connected devices periodically on macOS
  Future<void> _refreshConnectedDevices() async {
    try {
      await _addConnectedDevices();
    } catch (e, st) {
      AppLogger.warn('Error refreshing connected devices', error: e, stackTrace: st);
    }
  }

  // Helper to check if device type is audio-related
  bool _isAudioDevice(BluetoothDeviceType type) {
    return type == BluetoothDeviceType.speaker ||
        type == BluetoothDeviceType.headphones ||
        type == BluetoothDeviceType.earbuds;
  }

  void dispose() {
    _scanTimer?.cancel();
    _scanResultsController.close();
  }
}

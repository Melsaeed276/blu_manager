import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../../domain/entities/bluetooth_device_entity.dart';

class BluetoothDeviceModel extends BluetoothDeviceEntity {
  const BluetoothDeviceModel({
    required super.id,
    required super.name,
    required super.rawName,
    required super.rssi,
    required super.isConnected,
    required super.connectionState,
    required super.deviceType,
  });

  factory BluetoothDeviceModel.fromScanResult(fbp.ScanResult scanResult) {
    // Capture original raw advertised/platform name first
    String rawName = scanResult.device.platformName;
    if (rawName.isEmpty) {
      rawName = scanResult.advertisementData.advName;
    }

    var deviceType = _detectDeviceType(scanResult);

    // Display name logic
    String displayName = rawName; // start with raw

    // If type unknown -> ignore provided name and generate placeholder later
    if (deviceType == BluetoothDeviceType.unknown) {
      displayName = '';
    }

    if (displayName.isEmpty) {
      final deviceId = scanResult.device.remoteId.toString();
      final suffix = deviceId.length >= 4 ? deviceId.substring(deviceId.length - 4) : deviceId;
      switch (deviceType) {
        case BluetoothDeviceType.speaker:
          displayName = 'Bluetooth Speaker ($suffix)';
          break;
        case BluetoothDeviceType.headphones:
          displayName = 'Bluetooth Headphones ($suffix)';
          break;
        case BluetoothDeviceType.earbuds:
          displayName = 'Bluetooth Earbuds ($suffix)';
          break;
        case BluetoothDeviceType.phone:
          displayName = 'Mobile Device ($suffix)';
          break;
        case BluetoothDeviceType.computer:
          displayName = 'Computer ($suffix)';
          break;
        case BluetoothDeviceType.mouse:
          displayName = 'Bluetooth Mouse ($suffix)';
          break;
        case BluetoothDeviceType.keyboard:
          displayName = 'Bluetooth Keyboard ($suffix)';
          break;
        default:
          displayName = 'Bluetooth Device ($suffix)';
      }
    }

    return BluetoothDeviceModel(
      id: scanResult.device.remoteId.toString(),
      name: displayName,
      rawName: rawName,
      rssi: scanResult.rssi,
      isConnected: false,
      connectionState: BluetoothConnectionState.disconnected,
      deviceType: deviceType,
    );
  }

  factory BluetoothDeviceModel.fromBluetoothDevice(
    fbp.BluetoothDevice device, {
    int rssi = 0,
    bool isConnected = false,
    BluetoothConnectionState connectionState = BluetoothConnectionState.disconnected,
    BluetoothDeviceType deviceType = BluetoothDeviceType.unknown,
  }) {
    final rawName = device.platformName;
    String displayName = rawName.isEmpty && deviceType != BluetoothDeviceType.unknown
        ? 'Bluetooth Device'
        : rawName;
    if (deviceType == BluetoothDeviceType.unknown) {
      displayName = rawName.isEmpty ? 'Bluetooth Device' : 'Bluetooth Device'; // force placeholder style
    }
    return BluetoothDeviceModel(
      id: device.remoteId.toString(),
      name: displayName,
      rawName: rawName,
      rssi: rssi,
      isConnected: isConnected,
      connectionState: connectionState,
      deviceType: deviceType,
    );
  }

  @override
  BluetoothDeviceModel copyWith({
    String? id,
    String? name,
    String? rawName,
    int? rssi,
    bool? isConnected,
    BluetoothConnectionState? connectionState,
    BluetoothDeviceType? deviceType,
  }) {
    return BluetoothDeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      rawName: rawName ?? this.rawName,
      rssi: rssi ?? this.rssi,
      isConnected: isConnected ?? this.isConnected,
      connectionState: connectionState ?? this.connectionState,
      deviceType: deviceType ?? this.deviceType,
    );
  }

  static BluetoothConnectionState mapConnectionState(fbp.BluetoothConnectionState state) {
    switch (state) {
      case fbp.BluetoothConnectionState.disconnected:
        return BluetoothConnectionState.disconnected;
      case fbp.BluetoothConnectionState.connected:
        return BluetoothConnectionState.connected;
      default:
        return BluetoothConnectionState.disconnected;
    }
  }

  // Enhanced device type detection for better categorization
  static BluetoothDeviceType _detectDeviceType(fbp.ScanResult scanResult) {
    final services = scanResult.advertisementData.serviceUuids;
    final deviceName = (scanResult.device.platformName.isNotEmpty
        ? scanResult.device.platformName
        : scanResult.advertisementData.advName).toLowerCase();
    final manufacturerData = scanResult.advertisementData.manufacturerData;

    // Check by Bluetooth service UUIDs first (most reliable)
    for (final serviceUuid in services) {
      final uuidString = serviceUuid.toString().toLowerCase();

      // Audio devices - Enhanced detection
      if (uuidString.contains('110b') || // Audio Sink
          uuidString.contains('110a') || // Audio Source
          uuidString.contains('110d') || // Advanced Audio Distribution Profile
          uuidString.contains('111e') || // Hands-Free Profile
          uuidString.contains('1108') || // Headset Profile
          uuidString.contains('180f') || // Battery Service (common in audio devices)
          uuidString.contains('1822')) {  // Pulse Oximeter Service (smartwatches/fitness)

        // Determine specific audio device type
        if (deviceName.contains('speaker') || deviceName.contains('soundbar') ||
            deviceName.contains('boom') || deviceName.contains('studio')) {
          return BluetoothDeviceType.speaker;
        } else if (deviceName.contains('airpods') || deviceName.contains('earbuds') ||
                   deviceName.contains('galaxy buds') || deviceName.contains('pixel buds')) {
          return BluetoothDeviceType.earbuds;
        } else if (deviceName.contains('headphones') || deviceName.contains('headset') ||
                   deviceName.contains('beats') || deviceName.contains('sony') ||
                   deviceName.contains('bose')) {
          return BluetoothDeviceType.headphones;
        } else {
          // Default to speaker for unknown audio devices
          return BluetoothDeviceType.speaker;
        }
      }

      // Input devices
      if (uuidString.contains('1812')) { // Human Interface Device
        if (deviceName.contains('mouse') || deviceName.contains('trackpad')) {
          return BluetoothDeviceType.mouse;
        } else if (deviceName.contains('keyboard')) {
          return BluetoothDeviceType.keyboard;
        } else if (deviceName.contains('controller') || deviceName.contains('gamepad')) {
          return BluetoothDeviceType.gameController;
        }
      }

      // Health devices
      if (uuidString.contains('180d') || // Heart Rate
          uuidString.contains('1816') || // Cycling Speed and Cadence
          uuidString.contains('1818') || // Cycling Power
          uuidString.contains('181c')) {  // User Data
        return BluetoothDeviceType.healthDevice;
      }

      // Printer
      if (uuidString.contains('1120') || uuidString.contains('1121')) {
        return BluetoothDeviceType.printer;
      }
    }

    // Check by manufacturer data (Apple devices, etc.)
    if (manufacturerData.isNotEmpty) {
      for (final entry in manufacturerData.entries) {
        final manufacturerId = entry.key;

        // Apple devices (0x004C)
        if (manufacturerId == 0x004C) {
          if (deviceName.contains('iphone')) {
            return BluetoothDeviceType.phone;
          } else if (deviceName.contains('ipad')) {
            return BluetoothDeviceType.tablet;
          } else if (deviceName.contains('macbook') || deviceName.contains('imac') ||
                     deviceName.contains('mac mini')) {
            return BluetoothDeviceType.computer;
          } else if (deviceName.contains('watch')) {
            return BluetoothDeviceType.smartwatch;
          } else if (deviceName.contains('airpods')) {
            return BluetoothDeviceType.earbuds;
          }
        }

        // Samsung devices (0x0075)
        else if (manufacturerId == 0x0075) {
          if (deviceName.contains('galaxy') && deviceName.contains('buds')) {
            return BluetoothDeviceType.earbuds;
          } else if (deviceName.contains('galaxy') && deviceName.contains('watch')) {
            return BluetoothDeviceType.smartwatch;
          }
        }
      }
    }

    // Fallback to name-based detection with enhanced patterns
    if (deviceName.isNotEmpty) {
      // Audio devices
      if (deviceName.contains('speaker') || deviceName.contains('soundbar') ||
          deviceName.contains('boom') || deviceName.contains('jbl') ||
          deviceName.contains('bose') && deviceName.contains('speaker')) {
        return BluetoothDeviceType.speaker;
      }

      if (deviceName.contains('airpods') || deviceName.contains('earbuds') ||
          deviceName.contains('galaxy buds') || deviceName.contains('pixel buds') ||
          deviceName.contains('jabra') && deviceName.contains('elite')) {
        return BluetoothDeviceType.earbuds;
      }

      if (deviceName.contains('headphones') || deviceName.contains('headset') ||
          deviceName.contains('beats') || deviceName.contains('sony wh') ||
          deviceName.contains('bose') && !deviceName.contains('speaker')) {
        return BluetoothDeviceType.headphones;
      }

      // Computers and mobile devices
      if (deviceName.contains('iphone') || deviceName.contains('samsung') ||
          deviceName.contains('pixel') || deviceName.contains('oneplus')) {
        return BluetoothDeviceType.phone;
      }

      if (deviceName.contains('ipad') || deviceName.contains('tablet')) {
        return BluetoothDeviceType.tablet;
      }

      if (deviceName.contains('macbook') || deviceName.contains('imac') ||
          deviceName.contains('laptop') || deviceName.contains('desktop') ||
          deviceName.contains('pc')) {
        return BluetoothDeviceType.computer;
      }

      // Input devices
      if (deviceName.contains('mouse') || deviceName.contains('trackpad')) {
        return BluetoothDeviceType.mouse;
      }

      if (deviceName.contains('keyboard')) {
        return BluetoothDeviceType.keyboard;
      }

      if (deviceName.contains('controller') || deviceName.contains('gamepad') ||
          deviceName.contains('xbox') || deviceName.contains('playstation')) {
        return BluetoothDeviceType.gameController;
      }

      // Other devices
      if (deviceName.contains('watch')) {
        return BluetoothDeviceType.smartwatch;
      }

      if (deviceName.contains('printer')) {
        return BluetoothDeviceType.printer;
      }

      if (deviceName.contains('camera')) {
        return BluetoothDeviceType.camera;
      }

      if (deviceName.contains('car') || deviceName.contains('bmw') ||
          deviceName.contains('mercedes') || deviceName.contains('audi')) {
        return BluetoothDeviceType.car;
      }

      if (deviceName.contains('tv') || deviceName.contains('chromecast') ||
          deviceName.contains('roku') || deviceName.contains('firestick') || deviceName.contains('LG'))  {
        return BluetoothDeviceType.tv;
      }
    }

    return BluetoothDeviceType.unknown;
  }
}

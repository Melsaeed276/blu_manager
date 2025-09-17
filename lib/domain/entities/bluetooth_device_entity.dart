import 'package:equatable/equatable.dart';

class BluetoothDeviceEntity extends Equatable {
  final String id;
  final String name; // Display name (may be placeholder if unknown type)
  final String rawName; // Original advertised/platform name (may be empty)
  final int rssi;
  final bool isConnected;
  final BluetoothConnectionState connectionState;
  final BluetoothDeviceType deviceType;

  const BluetoothDeviceEntity({
    required this.id,
    required this.name,
    this.rawName = '',
    required this.rssi,
    required this.isConnected,
    required this.connectionState,
    required this.deviceType,
  });

  static const BluetoothDeviceEntity empty = BluetoothDeviceEntity(
    id: '',
    name: '',
    rawName: '',
    rssi: 0,
    isConnected: false,
    connectionState: BluetoothConnectionState.disconnected,
    deviceType: BluetoothDeviceType.unknown,
  );

  BluetoothDeviceEntity copyWith({
    String? id,
    String? name,
    int? rssi,
    bool? isConnected,
    BluetoothConnectionState? connectionState,
    BluetoothDeviceType? deviceType,
  }) {
    return BluetoothDeviceEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      isConnected: isConnected ?? this.isConnected,
      connectionState: connectionState ?? this.connectionState,
      deviceType: deviceType ?? this.deviceType,
    );
  }

  @override
  List<Object?> get props => [id, name, rssi, isConnected, connectionState, deviceType];
}

enum BluetoothConnectionState {
  disconnected,
  connected,
}

enum BluetoothDeviceType {
  computer,
  phone,
  tablet,
  speaker,
  headphones,
  earbuds,
  smartwatch,
  keyboard,
  mouse,
  gameController,
  printer,
  camera,
  car,
  tv,
  healthDevice,
  unknown,
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../domain/entities/bluetooth_device_entity.dart';
import '../../domain/entities/file_transfer_entity.dart';
import '../../domain/usecases/bluetooth_usecases.dart';
import '../../domain/usecases/file_transfer_usecases.dart';
import '../../core/usecases/usecase.dart';
import '../providers/dependency_injection.dart';

// State for Device Detail
class DeviceDetailState {
  final BluetoothDeviceEntity device;
  final BluetoothConnectionState connectionState;
  final bool isConnecting;
  final List<FileTransferEntity> transfers;
  final String? errorMessage;
  final String? successMessage;

  const DeviceDetailState({
    required this.device,
    this.connectionState = BluetoothConnectionState.disconnected,
    this.isConnecting = false,
    this.transfers = const [],
    this.errorMessage,
    this.successMessage,
  });

  DeviceDetailState copyWith({
    BluetoothDeviceEntity? device,
    BluetoothConnectionState? connectionState,
    bool? isConnecting,
    List<FileTransferEntity>? transfers,
    String? errorMessage,
    String? successMessage,
  }) {
    return DeviceDetailState(
      device: device ?? this.device,
      connectionState: connectionState ?? this.connectionState,
      isConnecting: isConnecting ?? this.isConnecting,
      transfers: transfers ?? this.transfers,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  bool get isConnected => connectionState == BluetoothConnectionState.connected;
}

class DeviceDetailNotifier extends Notifier<DeviceDetailState> {
  BluetoothDeviceEntity _device = BluetoothDeviceEntity.empty;

  @override
  DeviceDetailState build() {
    // Start with an empty device until setDevice is invoked by the page
    return DeviceDetailState(device: _device);
  }

  void setDevice(BluetoothDeviceEntity deviceEntity) {
    _device = deviceEntity;
    state = state.copyWith(device: _device);
  }

  Future<void> connectToDevice() async {
    if (_device.id.isEmpty) return; // device not set yet
    if (state.isConnecting || state.isConnected) return;

    state = state.copyWith(isConnecting: true, errorMessage: null);

    try {
      final connectUseCase = ref.read(connectToDeviceProvider);
      final result = await connectUseCase
          .call(ConnectToDeviceParams(deviceId: _device.id))
          .timeout(const Duration(seconds: 12));

      if (!ref.mounted) return;

      if (result) {
        state = state.copyWith(
          connectionState: BluetoothConnectionState.connected,
          isConnecting: false,
          successMessage: 'Connected successfully',
        );
      } else {
        state = state.copyWith(
          isConnecting: false,
          errorMessage: 'Failed to connect to device',
        );
      }
    } on TimeoutException {
      if (!ref.mounted) return;
      state = state.copyWith(
        isConnecting: false,
        errorMessage:
            'Connection timeout. Ensure the device is powered on, in range, and advertising.',
      );
    } catch (e) {
      if (!ref.mounted) return;
      final msg = e.toString();
      String friendly = msg;
      final lower = msg.toLowerCase();
      if (lower.contains('timeout') || lower.contains('[fbp]') && lower.contains('timeout')) {
        friendly =
            'Connection timeout. Ensure the device is powered on, in range, and advertising.';
      }
      state = state.copyWith(
        isConnecting: false,
        errorMessage: friendly.startsWith('Connection failed:') ? friendly : 'Connection failed: $friendly',
      );
    }
  }

  Future<void> disconnectFromDevice() async {
    if (!state.isConnected) return;

    try {
      final disconnectUseCase = ref.read(disconnectFromDeviceProvider);
      await disconnectUseCase.call(
        DisconnectFromDeviceParams(deviceId: _device.id),
      );
      if (!ref.mounted) return;
      state = state.copyWith(
        connectionState: BluetoothConnectionState.disconnected,
        successMessage: 'Disconnected successfully',
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        errorMessage: 'Disconnection failed: ${e.toString()}',
      );
    }
  }

  Future<void> sendFile() async {
    if (!state.isConnected) {
      state = state.copyWith(errorMessage: 'Device is not connected');
      return;
    }

    try {
      final pickFileUseCase = ref.read(pickFileProvider);
      final filePath = await pickFileUseCase.call(const NoParams());

      if (!ref.mounted) return;

      if (filePath != null && filePath.isNotEmpty) {
        final sendFileUseCase = ref.read(sendFileProvider);
        final result = await sendFileUseCase.call(
          SendFileParams(deviceId: _device.id, filePath: filePath),
        );

        if (!ref.mounted) return;

        if (result) {
          try {
            final transfer = FileTransferEntity(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              fileName: filePath.split('/').last,
              filePath: filePath,
              fileSize: 0,
              fileType: FileType.other,
              direction: TransferDirection.send,
              status: TransferStatus.completed,
              progress: 1.0,
              createdAt: DateTime.now(),
            );

            final updatedTransfers = [...state.transfers, transfer];
            state = state.copyWith(
              transfers: updatedTransfers,
              successMessage: 'File sent successfully',
            );
          } catch (_) {
            if (!ref.mounted) return;
            state = state.copyWith(successMessage: 'File sent successfully');
          }
        } else {
          state = state.copyWith(errorMessage: 'Failed to send file');
        }
      } else {
        state = state.copyWith(errorMessage: 'No file selected');
      }
    } catch (e) {
      if (!ref.mounted) return;
      String errorMessage = e.toString();
      final lower = errorMessage.toLowerCase();
      if (lower.contains('permission')) {
        errorMessage = 'Permission denied. Please check file permissions.';
      } else if (lower.contains('no writable characteristic found') ||
          lower.contains('not accept ble gatt writes') ||
          lower.contains('not be accepted') ||
          lower.contains('not compatible with ble file transfer') ||
          lower.contains('request is not supported') ||
          lower.contains('no writable gatt characteristic')) {
        errorMessage =
            'Device does not support file transfer (no writable GATT characteristic).';
      } else if (lower.contains('device does not support file transfer')) {
        errorMessage = 'Device does not support file transfer.';
      }

      state = state.copyWith(errorMessage: errorMessage);
    }
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}

final deviceDetailNotifierProvider =
    NotifierProvider.autoDispose<DeviceDetailNotifier, DeviceDetailState>(
      DeviceDetailNotifier.new,
    );

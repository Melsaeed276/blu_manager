import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// Controller to manage device detail state
class DeviceDetailController extends StateNotifier<DeviceDetailState> {
  DeviceDetailController(this.ref, BluetoothDeviceEntity device)
      : super(DeviceDetailState(device: device));

  final Ref ref;

  void clearMessages() {
    state = state.copyWith(
      errorMessage: null,
      successMessage: null,
    );
  }

  Future<void> connectToDevice() async {
    if (state.isConnecting || state.isConnected) return;

    state = state.copyWith(
      isConnecting: true,
      errorMessage: null,
    );

    try {
      final connectUseCase = ref.read(connectToDeviceProvider);
      final result = await connectUseCase.call(ConnectToDeviceParams(
        device: state.device,
      ));

      if (result.isSuccess) {
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
    } catch (e) {
      state = state.copyWith(
        isConnecting: false,
        errorMessage: 'Connection failed: ${e.toString()}',
      );
    }
  }

  Future<void> disconnectFromDevice() async {
    if (!state.isConnected) return;

    try {
      final disconnectUseCase = ref.read(disconnectFromDeviceProvider);
      final result = await disconnectUseCase.call(DisconnectFromDeviceParams(
        device: state.device,
      ));

      if (result.isSuccess) {
        state = state.copyWith(
          connectionState: BluetoothConnectionState.disconnected,
          successMessage: 'Disconnected successfully',
        );
      } else {
        state = state.copyWith(
          errorMessage: 'Failed to disconnect from device',
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Disconnection failed: ${e.toString()}',
      );
    }
  }

  Future<void> sendFile() async {
    if (!state.isConnected) {
      state = state.copyWith(
        errorMessage: 'Device is not connected',
      );
      return;
    }

    try {
      // Pick file
      final pickFileUseCase = ref.read(pickFileProvider);
      final fileResult = await pickFileUseCase.call(const NoParams());

      if (fileResult.isSuccess && fileResult.data != null) {
        final filePath = fileResult.data!;

        // Send file
        final sendFileUseCase = ref.read(sendFileProvider);
        final result = await sendFileUseCase.call(SendFileParams(
          device: state.device,
          filePath: filePath,
        ));

        if (result.isSuccess) {
          // Update transfer history
          try {
            final transfer = FileTransferEntity(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              fileName: filePath.split('/').last,
              filePath: filePath,
              deviceId: state.device.id,
              direction: TransferDirection.sent,
              timestamp: DateTime.now(),
              status: TransferStatus.completed,
              fileSize: 0, // You might want to get actual file size
            );

            final updatedTransfers = [...state.transfers, transfer];
            state = state.copyWith(
              transfers: updatedTransfers,
              successMessage: 'File sent successfully',
            );
          } catch (e) {
            // Silently fail - transfer history is not critical
          }
        } else {
          state = state.copyWith(
            errorMessage: 'Failed to send file',
          );
        }
      } else {
        state = state.copyWith(
          errorMessage: 'No file selected',
        );
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('permission')) {
        errorMessage = 'Permission denied. Please check file permissions.';
      } else if (errorMessage.contains('No writable characteristic found')) {
        errorMessage = 'Device does not support file transfer.';
      }

      state = state.copyWith(
        errorMessage: errorMessage,
      );
    }
  }

  Future<void> receiveFile(String fileName) async {
    if (!state.isConnected) {
      state = state.copyWith(
        errorMessage: 'Device is not connected',
      );
      return;
    }

    try {
      final receiveFileUseCase = ref.read(receiveFileProvider);
      final result = await receiveFileUseCase.call(ReceiveFileParams(
        device: state.device,
        fileName: fileName,
      ));

      if (result.isSuccess) {
        state = state.copyWith(
          successMessage: 'Started receiving file: $fileName',
        );
      } else {
        state = state.copyWith(
          errorMessage: 'Failed to start file receive',
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Receive file error: ${e.toString()}',
      );
    }
  }
}

// Provider for DeviceDetailController
final deviceDetailControllerProvider = StateNotifierProvider.family<DeviceDetailController, DeviceDetailState, BluetoothDeviceEntity>((ref, device) {
  return DeviceDetailController(ref, device);
});

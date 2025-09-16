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

// Controller class for managing device details
class DeviceDetailController {
  final Ref ref;
  final BluetoothDeviceEntity device;

  DeviceDetailController(this.ref, this.device);

  Future<DeviceDetailState> connectToDevice(DeviceDetailState currentState) async {
    if (currentState.isConnecting || currentState.isConnected) return currentState;

    var newState = currentState.copyWith(
      isConnecting: true,
      errorMessage: null,
    );

    try {
      final connectUseCase = ref.read(connectToDeviceProvider);
      final result = await connectUseCase.call(ConnectToDeviceParams(
        deviceId: device.id,
      ));

      if (result) {
        newState = newState.copyWith(
          connectionState: BluetoothConnectionState.connected,
          isConnecting: false,
          successMessage: 'Connected successfully',
        );
      } else {
        newState = newState.copyWith(
          isConnecting: false,
          errorMessage: 'Failed to connect to device',
        );
      }
    } catch (e) {
      newState = newState.copyWith(
        isConnecting: false,
        errorMessage: 'Connection failed: ${e.toString()}',
      );
    }

    return newState;
  }

  Future<DeviceDetailState> disconnectFromDevice(DeviceDetailState currentState) async {
    if (!currentState.isConnected) return currentState;

    try {
      final disconnectUseCase = ref.read(disconnectFromDeviceProvider);
      await disconnectUseCase.call(DisconnectFromDeviceParams(
        deviceId: device.id,
      ));

      return currentState.copyWith(
        connectionState: BluetoothConnectionState.disconnected,
        successMessage: 'Disconnected successfully',
      );
    } catch (e) {
      return currentState.copyWith(
        errorMessage: 'Disconnection failed: ${e.toString()}',
      );
    }
  }

  Future<DeviceDetailState> sendFile(DeviceDetailState currentState) async {
    if (!currentState.isConnected) {
      return currentState.copyWith(
        errorMessage: 'Device is not connected',
      );
    }

    try {
      // Pick file
      final pickFileUseCase = ref.read(pickFileProvider);
      final filePath = await pickFileUseCase.call(const NoParams());

      if (filePath != null && filePath.isNotEmpty) {
        // Send file
        final sendFileUseCase = ref.read(sendFileProvider);
        final result = await sendFileUseCase.call(SendFileParams(
          deviceId: device.id,
          filePath: filePath,
        ));

        if (result) {
          // Update transfer history
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

            final updatedTransfers = [...currentState.transfers, transfer];
            return currentState.copyWith(
              transfers: updatedTransfers,
              successMessage: 'File sent successfully',
            );
          } catch (e) {
            // Silently fail - transfer history is not critical
            return currentState.copyWith(
              successMessage: 'File sent successfully',
            );
          }
        } else {
          return currentState.copyWith(
            errorMessage: 'Failed to send file',
          );
        }
      } else {
        return currentState.copyWith(
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

      return currentState.copyWith(
        errorMessage: errorMessage,
      );
    }
  }

  Future<DeviceDetailState> receiveFile(DeviceDetailState currentState, String fileName) async {
    if (!currentState.isConnected) {
      return currentState.copyWith(
        errorMessage: 'Device is not connected',
      );
    }

    try {
      final receiveFileUseCase = ref.read(receiveFileProvider);
      final result = await receiveFileUseCase.call(ReceiveFileParams(
        deviceId: device.id,
        fileName: fileName,
      ));

      if (result) {
        return currentState.copyWith(
          successMessage: 'Started receiving file: $fileName',
        );
      } else {
        return currentState.copyWith(
          errorMessage: 'Failed to start file receive',
        );
      }
    } catch (e) {
      return currentState.copyWith(
        errorMessage: 'Receive file error: ${e.toString()}',
      );
    }
  }

  DeviceDetailState clearMessages(DeviceDetailState currentState) {
    return currentState.copyWith(
      errorMessage: null,
      successMessage: null,
    );
  }
}

// Using Provider instead of StateProvider for compatibility
final deviceDetailStateProvider = Provider.family<DeviceDetailState, BluetoothDeviceEntity>((ref, device) {
  return DeviceDetailState(device: device);
});

// Provider for the controller
final deviceDetailControllerProvider = Provider.family<DeviceDetailController, BluetoothDeviceEntity>((ref, device) {
  return DeviceDetailController(ref, device);
});

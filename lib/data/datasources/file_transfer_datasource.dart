import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mime/mime.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../models/file_transfer_model.dart';
import '../../domain/entities/file_transfer_entity.dart';
import '../../core/utils/logger.dart';

abstract class FileTransferDataSource {
  Future<String?> pickFile();
  Future<bool> sendFile(String deviceId, String filePath);
  Future<bool> receiveFile(String deviceId, String fileName);
  Stream<FileTransferModel> getTransferProgress(String transferId);
  Future<List<FileTransferModel>> getTransferHistory();
  Future<void> cancelTransfer(String transferId);
  Future<String> getDownloadsDirectory();
}

class FileTransferDataSourceImpl implements FileTransferDataSource {
  final Map<String, StreamController<FileTransferModel>> _transferControllers =
      {};
  final List<FileTransferModel> _transferHistory = [];
  final Map<String, fbp.BluetoothDevice> _connectedDevices = {};

  // OBEX File Transfer Service UUID
  static const String _obexFileTransferServiceUuid =
      "00001106-0000-1000-8000-00805f9b34fb";
  static const String _obexCharacteristicUuid =
      "00002a00-0000-1000-8000-00805f9b34fb";

  @override
  Future<String?> pickFile() async {
    try {
      final result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.any,
        allowMultiple: false
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        AppLogger.info('File picked: $filePath');
        return filePath;
      }

      return null;
    } catch (e, st) {
      AppLogger.error('File picker error', error: e, stackTrace: st);
      throw Exception('Failed to pick file: $e');
    }
  }

  @override
  Future<bool> sendFile(String deviceId, String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      AppLogger.info('Attempting to send file to device=$deviceId path=$filePath');

      final transferId = '${DateTime.now().millisecondsSinceEpoch}';
      final transfer = FileTransferModel.fromFile(
        file,
        id: transferId,
        direction: TransferDirection.send,
        status: TransferStatus.inProgress,
      );

      // Add to history
      _transferHistory.add(transfer);

      // Create progress stream
      final controller = StreamController<FileTransferModel>();
      _transferControllers[transferId] = controller;

      // Attempt custom file transfer, but provide better user feedback
      final success = await _attemptCustomFileTransfer(
        deviceId,
        file,
        transferId,
        controller,
      );

      if (!success) {
        // Fallback: On Android, try system Bluetooth share (OPP) via share sheet
        if (Platform.isAndroid) {
          final shared = await _trySystemBluetoothShare(file);
          if (shared) {
            final completedTransfer = transfer.copyWith(
              progress: 1.0,
              status: TransferStatus.completed,
            );
            final index = _transferHistory.indexWhere(
              (t) => t.id == transferId,
            );
            _transferHistory[index] = completedTransfer;
            controller.add(completedTransfer);
            controller.close();
            _transferControllers.remove(transferId);
            AppLogger.info('File shared via system Bluetooth (OPP)');
            return true;
          }
        }

        // Otherwise, mark as failed with explicit guidance
        final failedTransfer = transfer.copyWith(
          status: TransferStatus.failed,
          progress: 0.0,
        );
        final index = _transferHistory.indexWhere((t) => t.id == transferId);
        _transferHistory[index] = failedTransfer;
        controller.add(failedTransfer);
        controller.close();
        _transferControllers.remove(transferId);

        AppLogger.error('File transfer failed: Target not compatible');
        throw Exception(
          'Target device is not compatible with BLE file transfer over GATT. Use a companion app/service or another method.',
        );
      }

      return true;
    } catch (e) {
      AppLogger.error('Send file error', error: e);
      rethrow;
    }
  }

  Future<bool> _attemptCustomFileTransfer(
    String deviceId,
    File file,
    String transferId,
    StreamController<FileTransferModel> controller,
  ) async {
    try {
      // Get connected device
      final connectedDevices = fbp.FlutterBluePlus.connectedDevices;
      fbp.BluetoothDevice? targetDevice;

      for (final device in connectedDevices) {
        if (device.remoteId.toString() == deviceId) {
          targetDevice = device;
          break;
        }
      }

      if (targetDevice == null) {
        throw Exception('Device not connected');
      }

      // Discover services to see what's available
      final services = await targetDevice.discoverServices();
      AppLogger.debug('Available services on device:');
      for (final service in services) {
        AppLogger.debug('Service UUID: ${service.uuid}');
        for (final characteristic in service.characteristics) {
          AppLogger.debug('  Char UUID: ${characteristic.uuid} props=${characteristic.properties}');
        }
      }

      // Look for a writable characteristic to attempt file transfer.
      // Prefer custom 128-bit UUIDs and avoid reserved/standard ones (0x2A**, 0x2B**, services 0x1800/0x1801/0x180A).
      fbp.BluetoothCharacteristic? writableCharacteristic;

      String norm(String uuid) => uuid.toLowerCase().replaceAll('-', '');
      bool isCustom128(String n) => n.length == 32 && !n.startsWith('0000');
      bool isAssignedBase(String n) =>
          n.length == 32 &&
          n.startsWith('0000') &&
          n.endsWith('00001000800000805f9b34fb');
      String shortOfBase(String n) =>
          isAssignedBase(n) ? n.substring(4, 8) : n;
      bool isReservedServiceN(String n) {
        final s = shortOfBase(n);
        return s == '1800' || s == '1801' || s == '180a';
      }

      bool isReservedCharN(String n) {
        final s = shortOfBase(n);
        // Any 0x2A** or 0x2B** characteristic is reserved/standard
        return (s.length == 4) && (s.startsWith('2a') || s.startsWith('2b'));
      }

      // Pass 1: Prefer custom 128-bit services with non-reserved writable chars
      for (final service in services) {
        final sNorm = norm(service.uuid.toString());
        if (!isCustom128(sNorm)) continue;
        for (final characteristic in service.characteristics) {
          final cNorm = norm(characteristic.uuid.toString());
          final canWrite =
              characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse;
          if (canWrite && !isReservedCharN(cNorm)) {
            writableCharacteristic = characteristic;
            break;
          }
        }
        if (writableCharacteristic != null) break;
      }

      // Pass 2: Any non-reserved service, non-reserved writable char
      if (writableCharacteristic == null) {
        for (final service in services) {
          final sNorm = norm(service.uuid.toString());
          if (isReservedServiceN(sNorm)) continue;
          for (final characteristic in service.characteristics) {
            final cNorm = norm(characteristic.uuid.toString());
            final canWrite =
                characteristic.properties.write ||
                characteristic.properties.writeWithoutResponse;
            if (canWrite && !isReservedCharN(cNorm)) {
              writableCharacteristic = characteristic;
              break;
            }
          }
          if (writableCharacteristic != null) break;
        }
      }

      if (writableCharacteristic == null) {
        AppLogger.warn('No writable characteristic found for file transfer');
        return false;
      }

      // Attempt to send file metadata first
      final fileName = file.path.split('/').last;
      final fileSize = await file.length();
      final metadata = {
        'action': 'file_transfer',
        'fileName': fileName,
        'fileSize': fileSize,
        'transferId': transferId,
      };

      final metadataBytes = utf8.encode(jsonEncode(metadata));

      // Check if metadata fits in characteristic
      if (metadataBytes.length > 512) {
        AppLogger.warn('File metadata too large (${metadataBytes.length} bytes)');
        return false;
      }

      // Send metadata using a supported write mode
      final bool supportsWrite = writableCharacteristic.properties.write;
      final bool supportsWriteNoResp =
          writableCharacteristic.properties.writeWithoutResponse;

      if (!supportsWrite && !supportsWriteNoResp) {
        AppLogger.warn('Characteristic does not support write/writeWithoutResponse');
        return false;
      }

      await writableCharacteristic.write(
        metadataBytes,
        withoutResponse: supportsWrite ? false : supportsWriteNoResp,
      );
      AppLogger.debug('Sent file metadata to device');

      // Progressive transfer. Prefer write-with-response when available.
      final fileBytes = await file.readAsBytes();
      int chunkSize = supportsWrite ? 180 : 20;
      int totalSent = 0;

      for (int i = 0; i < fileBytes.length; i += chunkSize) {
        final end = (i + chunkSize > fileBytes.length)
            ? fileBytes.length
            : i + chunkSize;
        final chunk = fileBytes.sublist(i, end);

        try {
          // Respect the characteristic's supported write mode
          await writableCharacteristic.write(
            chunk,
            withoutResponse: !supportsWrite && supportsWriteNoResp,
          );
          totalSent += chunk.length;

          // Update progress
          final currentTransfer = _transferHistory.firstWhere(
            (t) => t.id == transferId,
          );
          final progress = totalSent / fileBytes.length;
          final updatedTransfer = currentTransfer.copyWith(progress: progress);
          final index = _transferHistory.indexWhere((t) => t.id == transferId);
          _transferHistory[index] = updatedTransfer;
          controller.add(updatedTransfer);

          // Small delay to avoid overwhelming the connection
          await Future.delayed(const Duration(milliseconds: 50));
        } catch (e) {
          AppLogger.warn('Error sending chunk', error: e);
          // If failed due to write-without-response not supported, try with response once
          try {
            await writableCharacteristic.write(chunk, withoutResponse: false);
            totalSent += chunk.length;

            final currentTransfer = _transferHistory.firstWhere(
              (t) => t.id == transferId,
            );
            final progress = totalSent / fileBytes.length;
            final updatedTransfer = currentTransfer.copyWith(
              progress: progress,
            );
            final index = _transferHistory.indexWhere(
              (t) => t.id == transferId,
            );
            _transferHistory[index] = updatedTransfer;
            controller.add(updatedTransfer);
          } catch (e2) {
            AppLogger.error('Fallback write with response failed', error: e2);
            return false;
          }
        }
      }

      // Mark as completed
      final currentTransfer = _transferHistory.firstWhere(
        (t) => t.id == transferId,
      );
      final completedTransfer = currentTransfer.copyWith(
        progress: 1.0,
        status: TransferStatus.completed,
      );
      final index = _transferHistory.indexWhere((t) => t.id == transferId);
      _transferHistory[index] = completedTransfer;
      controller.add(completedTransfer);
      controller.close();
      _transferControllers.remove(transferId);

      AppLogger.info('File transfer completed successfully');
      return true;
    } catch (e) {
      AppLogger.error('Custom file transfer error', error: e);
      return false;
    }
  }

  // Android fallback to system Bluetooth share (OPP) via share sheet
  Future<bool> _trySystemBluetoothShare(File file) async {
    try {
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      await Share.shareXFiles(
        [XFile(file.path, mimeType: mimeType)],
        subject: 'Send via Bluetooth',
        text: 'Sharing file via system share',
      );
      return true;
    } catch (e) {
      AppLogger.error('System Bluetooth share failed', error: e);
      return false;
    }
  }

  @override
  Future<bool> receiveFile(String deviceId, String fileName) async {
    try {
      final downloadsDir = await getDownloadsDirectory();
      final filePath = '$downloadsDir/$fileName';

      final transferId = '${DateTime.now().millisecondsSinceEpoch}';
      final transfer = FileTransferModel(
        id: transferId,
        fileName: fileName,
        filePath: filePath,
        fileSize: 0, // Unknown until transfer starts
        fileType: FileType.other,
        direction: TransferDirection.receive,
        status: TransferStatus.inProgress,
        progress: 0.0,
        createdAt: DateTime.now(),
      );

      // Add to history
      _transferHistory.add(transfer);

      // Create progress stream
      final controller = StreamController<FileTransferModel>();
      _transferControllers[transferId] = controller;

      // Connect to the device
      final device = _connectedDevices[deviceId];
      if (device == null) {
        throw Exception('Device not connected');
      }

      // Discover services
      final services = await device.discoverServices();
      fbp.BluetoothService? fileTransferService;
      for (var service in services) {
        if (service.uuid.toString() == _obexFileTransferServiceUuid) {
          fileTransferService = service;
          break;
        }
      }

      if (fileTransferService == null) {
        throw Exception('OBEX File Transfer service not found');
      }

      // Get the OBEX characteristic
      final characteristic = fileTransferService.characteristics.firstWhere(
        (c) => c.uuid.toString() == _obexCharacteristicUuid,
        orElse: () => throw Exception('OBEX characteristic not found'),
      );

      // Write the file to the device
      final file = File(filePath);
      final sink = file.openWrite();

      characteristic.lastValueStream.listen(
        (data) {
          // Write received data to file
          sink.add(data);

          // Update transfer progress
          final currentTransfer = _transferHistory.firstWhere(
            (t) => t.id == transferId,
          );
          final newProgress =
              currentTransfer.progress + (data.length / file.lengthSync());
          final updatedTransfer = currentTransfer.copyWith(
            progress: newProgress,
          );
          final index = _transferHistory.indexWhere((t) => t.id == transferId);
          _transferHistory[index] = updatedTransfer;
          controller.add(updatedTransfer);
        },
        onDone: () async {
          // Transfer completed
          await sink.flush();
          await sink.close();
          final completedTransfer = transfer.copyWith(
            progress: 1.0,
            status: TransferStatus.completed,
          );
          final index = _transferHistory.indexWhere((t) => t.id == transferId);
          _transferHistory[index] = completedTransfer;
          controller.add(completedTransfer);
          controller.close();
          _transferControllers.remove(transferId);
        },
        onError: (e) {
          AppLogger.error('File receive stream error', error: e);
          sink.close();
          controller.close();
          _transferControllers.remove(transferId);
        },
      );

      // Send OBEX command to start receiving file
      final command = _createObexCommand(fileName);
      await characteristic.write(command, withoutResponse: true);

      return true;
    } catch (e) {
      AppLogger.error('Receive file error', error: e);
      return false;
    }
  }

  @override
  Stream<FileTransferModel> getTransferProgress(String transferId) {
    final controller = _transferControllers[transferId];
    if (controller == null) {
      return Stream.empty();
    }
    return controller.stream;
  }

  @override
  Future<List<FileTransferModel>> getTransferHistory() async {
    return List.from(_transferHistory);
  }

  @override
  Future<void> cancelTransfer(String transferId) async {
    final controller = _transferControllers[transferId];
    if (controller != null) {
      // Update transfer status
      final transferIndex = _transferHistory.indexWhere(
        (t) => t.id == transferId,
      );
      if (transferIndex != -1) {
        _transferHistory[transferIndex] = _transferHistory[transferIndex]
            .copyWith(status: TransferStatus.cancelled);

        controller.add(_transferHistory[transferIndex]);
      }

      controller.close();
      _transferControllers.remove(transferId);
    }
  }

  @override
  Future<String> getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      return '/storage/emulated/0/Download';
    } else {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    }
  }

  // Create OBEX command to start receiving file
  List<int> _createObexCommand(String fileName) {
    final fileNameBytes = utf8.encode(fileName);
    final command = <int>[
      0x01, // OBEX Connect command
      0x00, // Flags
      0x00, 0x00, // Code
      0x00, 0x00, 0x00, 0x00, // Length
      ...fileNameBytes,
    ];
    return command;
  }

  void dispose() {
    for (final controller in _transferControllers.values) {
      controller.close();
    }
    _transferControllers.clear();
  }
}

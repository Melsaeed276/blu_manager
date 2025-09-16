import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../models/file_transfer_model.dart';
import '../../domain/entities/file_transfer_entity.dart';

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
  final Map<String, StreamController<FileTransferModel>> _transferControllers = {};
  final List<FileTransferModel> _transferHistory = [];
  final Map<String, fbp.BluetoothDevice> _connectedDevices = {};

  // OBEX File Transfer Service UUID
  static const String _obexFileTransferServiceUuid = "00001106-0000-1000-8000-00805f9b34fb";
  static const String _obexCharacteristicUuid = "00002a00-0000-1000-8000-00805f9b34fb";

  @override
  Future<String?> pickFile() async {
    try {
      // On macOS, we don't need storage permission like Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission denied');
        }
      }

      final result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.any,
        allowMultiple: false,
        allowCompression: false, // Better for macOS
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        print('File picked: $filePath'); // Debug log
        return filePath;
      }

      return null;
    } catch (e) {
      print('File picker error: $e'); // Debug log
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

      print('Attempting to send file: $filePath to device: $deviceId');

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
      final success = await _attemptCustomFileTransfer(deviceId, file, transferId, controller);

      if (!success) {
        // Provide more specific error message for iPhone to MacBook transfers
        final failedTransfer = transfer.copyWith(
          status: TransferStatus.failed,
          progress: 0.0,
        );
        final index = _transferHistory.indexWhere((t) => t.id == transferId);
        _transferHistory[index] = failedTransfer;
        controller.add(failedTransfer);
        controller.close();
        _transferControllers.remove(transferId);

        print('File transfer failed: MacBook does not support direct Bluetooth file transfer from iOS apps. Consider using AirDrop, email, or cloud storage instead.');
        throw Exception('MacBook does not support direct Bluetooth file transfer. Use AirDrop or other methods.');
      }

      return true;
    } catch (e) {
      print('Send file error: $e');
      // Re-throw the exception so the UI can show the proper error message
      rethrow;
    }
  }

  Future<bool> _attemptCustomFileTransfer(
    String deviceId,
    File file,
    String transferId,
    StreamController<FileTransferModel> controller
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
      print('Available services on device:');
      for (final service in services) {
        print('Service UUID: ${service.uuid}');
        for (final characteristic in service.characteristics) {
          print('  Characteristic UUID: ${characteristic.uuid}');
          print('  Properties: ${characteristic.properties}');
        }
      }

      // Look for a writable characteristic to attempt file transfer
      fbp.BluetoothCharacteristic? writableCharacteristic;
      for (final service in services) {
        for (final characteristic in service.characteristics) {
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            writableCharacteristic = characteristic;
            break;
          }
        }
        if (writableCharacteristic != null) break;
      }

      if (writableCharacteristic == null) {
        print('No writable characteristic found for file transfer');
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
      if (metadataBytes.length > 512) { // Most characteristics have limited size
        print('File metadata too large for Bluetooth characteristic');
        return false;
      }

      // Send metadata
      await writableCharacteristic.write(metadataBytes);
      print('Sent file metadata to device');

      // For demonstration, show progressive transfer
      final fileBytes = await file.readAsBytes();
      final chunkSize = 20; // Small chunks for Bluetooth LE
      int totalSent = 0;

      for (int i = 0; i < fileBytes.length; i += chunkSize) {
        final end = (i + chunkSize > fileBytes.length) ? fileBytes.length : i + chunkSize;
        final chunk = fileBytes.sublist(i, end);

        try {
          await writableCharacteristic.write(chunk, withoutResponse: true);
          totalSent += chunk.length;

          // Update progress
          final currentTransfer = _transferHistory.firstWhere((t) => t.id == transferId);
          final progress = totalSent / fileBytes.length;
          final updatedTransfer = currentTransfer.copyWith(progress: progress);
          final index = _transferHistory.indexWhere((t) => t.id == transferId);
          _transferHistory[index] = updatedTransfer;
          controller.add(updatedTransfer);

          // Small delay to avoid overwhelming the connection
          await Future.delayed(const Duration(milliseconds: 50));
        } catch (e) {
          print('Error sending chunk: $e');
          return false;
        }
      }

      // Mark as completed
      final currentTransfer = _transferHistory.firstWhere((t) => t.id == transferId);
      final completedTransfer = currentTransfer.copyWith(
        progress: 1.0,
        status: TransferStatus.completed,
      );
      final index = _transferHistory.indexWhere((t) => t.id == transferId);
      _transferHistory[index] = completedTransfer;
      controller.add(completedTransfer);
      controller.close();
      _transferControllers.remove(transferId);

      print('File transfer completed successfully');
      return true;

    } catch (e) {
      print('Custom file transfer error: $e');
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

      characteristic.value.listen(
        (data) {
          // Write received data to file
          sink.add(data);

          // Update transfer progress
          final currentTransfer = _transferHistory.firstWhere((t) => t.id == transferId);
          final newProgress = currentTransfer.progress + (data.length / file.lengthSync());
          final updatedTransfer = currentTransfer.copyWith(progress: newProgress);
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
          print('File receive error: $e');
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
      print('Receive file error: $e');
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
      final transferIndex = _transferHistory.indexWhere((t) => t.id == transferId);
      if (transferIndex != -1) {
        _transferHistory[transferIndex] = _transferHistory[transferIndex].copyWith(
          status: TransferStatus.cancelled,
        );

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

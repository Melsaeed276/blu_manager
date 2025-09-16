import '../entities/file_transfer_entity.dart';

abstract class FileTransferRepository {
  Future<String?> pickFile();
  Future<bool> sendFile(String deviceId, String filePath);
  Future<bool> receiveFile(String deviceId, String fileName);
  Stream<FileTransferEntity> getTransferProgress(String transferId);
  Future<List<FileTransferEntity>> getTransferHistory();
  Future<void> cancelTransfer(String transferId);
  Future<String> getDownloadsDirectory();
}

import '../../domain/entities/file_transfer_entity.dart';
import '../../domain/repositories/file_transfer_repository.dart';
import '../datasources/file_transfer_datasource.dart';

class FileTransferRepositoryImpl implements FileTransferRepository {
  final FileTransferDataSource dataSource;

  FileTransferRepositoryImpl({required this.dataSource});

  @override
  Future<String?> pickFile() {
    return dataSource.pickFile();
  }

  @override
  Future<bool> sendFile(String deviceId, String filePath) {
    return dataSource.sendFile(deviceId, filePath);
  }

  @override
  Future<bool> receiveFile(String deviceId, String fileName) {
    return dataSource.receiveFile(deviceId, fileName);
  }

  @override
  Stream<FileTransferEntity> getTransferProgress(String transferId) {
    return dataSource.getTransferProgress(transferId);
  }

  @override
  Future<List<FileTransferEntity>> getTransferHistory() {
    return dataSource.getTransferHistory();
  }

  @override
  Future<void> cancelTransfer(String transferId) {
    return dataSource.cancelTransfer(transferId);
  }

  @override
  Future<String> getDownloadsDirectory() {
    return dataSource.getDownloadsDirectory();
  }
}

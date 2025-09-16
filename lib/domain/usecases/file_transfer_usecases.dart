import '../entities/file_transfer_entity.dart';
import '../repositories/file_transfer_repository.dart';
import '../../core/usecases/usecase.dart';

class SendFile extends UseCase<bool, SendFileParams> {
  final FileTransferRepository repository;

  SendFile(this.repository);

  @override
  Future<bool> call(SendFileParams params) {
    return repository.sendFile(params.deviceId, params.filePath);
  }
}

class ReceiveFile extends UseCase<bool, ReceiveFileParams> {
  final FileTransferRepository repository;

  ReceiveFile(this.repository);

  @override
  Future<bool> call(ReceiveFileParams params) {
    return repository.receiveFile(params.deviceId, params.fileName);
  }
}

class PickFile extends UseCase<String?, NoParams> {
  final FileTransferRepository repository;

  PickFile(this.repository);

  @override
  Future<String?> call(NoParams params) {
    return repository.pickFile();
  }
}

class GetTransferProgress extends StreamUseCase<FileTransferEntity, GetTransferProgressParams> {
  final FileTransferRepository repository;

  GetTransferProgress(this.repository);

  @override
  Stream<FileTransferEntity> call(GetTransferProgressParams params) {
    return repository.getTransferProgress(params.transferId);
  }
}

class GetTransferHistory extends UseCase<List<FileTransferEntity>, NoParams> {
  final FileTransferRepository repository;

  GetTransferHistory(this.repository);

  @override
  Future<List<FileTransferEntity>> call(NoParams params) {
    return repository.getTransferHistory();
  }
}

class CancelTransfer extends UseCase<void, CancelTransferParams> {
  final FileTransferRepository repository;

  CancelTransfer(this.repository);

  @override
  Future<void> call(CancelTransferParams params) {
    return repository.cancelTransfer(params.transferId);
  }
}

// Parameter classes
class SendFileParams {
  final String deviceId;
  final String filePath;

  SendFileParams({required this.deviceId, required this.filePath});
}

class ReceiveFileParams {
  final String deviceId;
  final String fileName;

  ReceiveFileParams({required this.deviceId, required this.fileName});
}

class GetTransferProgressParams {
  final String transferId;

  GetTransferProgressParams({required this.transferId});
}

class CancelTransferParams {
  final String transferId;

  CancelTransferParams({required this.transferId});
}

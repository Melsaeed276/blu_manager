import 'package:equatable/equatable.dart';

class FileTransferEntity extends Equatable {
  final String id;
  final String fileName;
  final String filePath;
  final int fileSize;
  final FileType fileType;
  final TransferDirection direction;
  final TransferStatus status;
  final double progress;
  final DateTime createdAt;

  const FileTransferEntity({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.fileType,
    required this.direction,
    required this.status,
    required this.progress,
    required this.createdAt,
  });

  FileTransferEntity copyWith({
    String? id,
    String? fileName,
    String? filePath,
    int? fileSize,
    FileType? fileType,
    TransferDirection? direction,
    TransferStatus? status,
    double? progress,
    DateTime? createdAt,
  }) {
    return FileTransferEntity(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      fileType: fileType ?? this.fileType,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fileName,
        filePath,
        fileSize,
        fileType,
        direction,
        status,
        progress,
        createdAt,
      ];
}

enum FileType {
  pdf,
  image,
  audio,
  video,
  document,
  other,
}

enum TransferDirection {
  send,
  receive,
}

enum TransferStatus {
  pending,
  inProgress,
  completed,
  failed,
  cancelled,
}

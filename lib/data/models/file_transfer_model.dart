import 'dart:io';
import 'package:mime/mime.dart';
import '../../domain/entities/file_transfer_entity.dart';

class FileTransferModel extends FileTransferEntity {
  const FileTransferModel({
    required super.id,
    required super.fileName,
    required super.filePath,
    required super.fileSize,
    required super.fileType,
    required super.direction,
    required super.status,
    required super.progress,
    required super.createdAt,
  });

  factory FileTransferModel.fromFile(
    File file, {
    required String id,
    required TransferDirection direction,
    TransferStatus status = TransferStatus.pending,
    double progress = 0.0,
  }) {
    final fileName = file.path.split('/').last;
    final fileSize = file.lengthSync();
    final mimeType = lookupMimeType(file.path);
    final fileType = _getFileTypeFromMime(mimeType);

    return FileTransferModel(
      id: id,
      fileName: fileName,
      filePath: file.path,
      fileSize: fileSize,
      fileType: fileType,
      direction: direction,
      status: status,
      progress: progress,
      createdAt: DateTime.now(),
    );
  }

  factory FileTransferModel.fromJson(Map<String, dynamic> json) {
    return FileTransferModel(
      id: json['id'],
      fileName: json['fileName'],
      filePath: json['filePath'],
      fileSize: json['fileSize'],
      fileType: FileType.values[json['fileType']],
      direction: TransferDirection.values[json['direction']],
      status: TransferStatus.values[json['status']],
      progress: json['progress'].toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'fileSize': fileSize,
      'fileType': fileType.index,
      'direction': direction.index,
      'status': status.index,
      'progress': progress,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  FileTransferModel copyWith({
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
    return FileTransferModel(
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

  static FileType _getFileTypeFromMime(String? mimeType) {
    if (mimeType == null) return FileType.other;

    if (mimeType.startsWith('image/')) return FileType.image;
    if (mimeType.startsWith('audio/')) return FileType.audio;
    if (mimeType.startsWith('video/')) return FileType.video;
    if (mimeType == 'application/pdf') return FileType.pdf;
    if (mimeType.startsWith('text/') ||
        mimeType.contains('document') ||
        mimeType.contains('word') ||
        mimeType.contains('excel') ||
        mimeType.contains('powerpoint')) {
      return FileType.document;
    }

    return FileType.other;
  }
}

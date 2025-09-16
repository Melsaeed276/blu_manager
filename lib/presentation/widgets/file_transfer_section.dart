import 'package:flutter/material.dart';
import '../../domain/entities/file_transfer_entity.dart';

class FileTransferSection extends StatelessWidget {
  final VoidCallback onSendFile;
  final Function(String) onReceiveFile;
  final List<FileTransferEntity> transfers;

  const FileTransferSection({
    super.key,
    required this.onSendFile,
    required this.onReceiveFile,
    required this.transfers,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File Transfer Actions
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'File Transfer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onSendFile,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Send File'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showReceiveFileDialog(context),
                        icon: const Icon(Icons.download),
                        label: const Text('Receive File'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Transfer History
        if (transfers.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transfer History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...transfers.take(5).map((transfer) => _buildTransferItem(transfer)),
                  if (transfers.length > 5)
                    TextButton(
                      onPressed: () => _showAllTransfers(context),
                      child: const Text('View All Transfers'),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTransferItem(FileTransferEntity transfer) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _getFileTypeIcon(transfer.fileType),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transfer.fileName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_formatFileSize(transfer.fileSize)} • ${_getDirectionText(transfer.direction)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          _getStatusIndicator(transfer.status, transfer.progress),
        ],
      ),
    );
  }

  Icon _getFileTypeIcon(FileType fileType) {
    IconData iconData;
    Color color;

    switch (fileType) {
      case FileType.pdf:
        iconData = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case FileType.image:
        iconData = Icons.image;
        color = Colors.blue;
        break;
      case FileType.audio:
        iconData = Icons.audio_file;
        color = Colors.purple;
        break;
      case FileType.video:
        iconData = Icons.video_file;
        color = Colors.orange;
        break;
      case FileType.document:
        iconData = Icons.description;
        color = Colors.green;
        break;
      case FileType.other:
      iconData = Icons.insert_drive_file;
        color = Colors.grey;
        break;
    }

    return Icon(iconData, color: color, size: 20);
  }

  String _getDirectionText(TransferDirection direction) {
    return direction == TransferDirection.send ? 'Sent' : 'Received';
  }

  Widget _getStatusIndicator(TransferStatus status, double progress) {
    switch (status) {
      case TransferStatus.inProgress:
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 2,
          ),
        );
      case TransferStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green, size: 20);
      case TransferStatus.failed:
        return const Icon(Icons.error, color: Colors.red, size: 20);
      case TransferStatus.cancelled:
        return const Icon(Icons.cancel, color: Colors.orange, size: 20);
      case TransferStatus.pending:
      return const Icon(Icons.schedule, color: Colors.grey, size: 20);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _showReceiveFileDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Receive File'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'File Name',
            hintText: 'Enter the name of the file to receive',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onReceiveFile(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Receive'),
          ),
        ],
      ),
    );
  }

  void _showAllTransfers(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Transfers'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: transfers.length,
            itemBuilder: (context, index) => _buildTransferItem(transfers[index]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

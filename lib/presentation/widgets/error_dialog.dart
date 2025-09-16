import 'package:flutter/material.dart';

class ErrorDialog extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const ErrorDialog({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.error, color: Colors.red),
          SizedBox(width: 8),
          Text('Error'),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onDismiss();
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}

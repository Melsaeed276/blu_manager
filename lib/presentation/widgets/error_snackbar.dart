import 'package:flutter/material.dart';

class ErrorSnackBar extends SnackBar {
  ErrorSnackBar({
    super.key,
    required String message,
  }) : super(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {},
          ),
        );
}

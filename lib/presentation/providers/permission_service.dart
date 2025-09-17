import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  const PermissionService();

  Future<void> requestStartupPermissions() async {
    if (Platform.isAndroid) {
      await _requestAndroidPermissions();
    } else if (Platform.isIOS) {
      await _requestIosPermissions();
    } else if (Platform.isMacOS) {
      // macOS prompts come from sandbox entitlements and file pickers; nothing to pre-request
    }
  }

  Future<void> _requestAndroidPermissions() async {
    final List<Permission> toRequest = <Permission>[
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
      // Request both legacy storage and Android 13+ media categories.
      // permission_handler will no-op as appropriate for the OS version.
      Permission.storage,
      Permission.photos, // READ_MEDIA_IMAGES on Android 13+
      Permission.videos, // READ_MEDIA_VIDEO on Android 13+
      Permission.audio, // READ_MEDIA_AUDIO on Android 13+
    ];

    await toRequest.request();

    // If permanently denied, guide user to app settings (best-effort)
    final bool anyPermanentlyDenied = await Future.wait(
      toRequest.map((p) => p.isPermanentlyDenied),
    ).then((list) => list.any((v) => v));
    if (anyPermanentlyDenied) {
      await openAppSettings();
    }
  }

  Future<void> _requestIosPermissions() async {
    // Bluetooth prompt
    await Permission.bluetooth.request();
    // iOS file access uses UIDocumentPicker; no global storage permission
  }
}

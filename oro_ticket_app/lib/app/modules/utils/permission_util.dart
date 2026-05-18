// lib/utils/permission_util.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestBluetoothPermissions() async {
  try {
    // Request all permissions in parallel — much faster
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request().timeout(
      const Duration(seconds: 6),
      onTimeout: () {
        debugPrint('⚠️ Permission requests timed out');
        return {};
      },
    );

    final anyPermanentlyDenied =
        statuses.values.any((status) => status.isPermanentlyDenied);

    if (anyPermanentlyDenied) {
      // Delay dialog until Navigator is ready
      // Never use barrierDismissible: false at startup — it can hang
      await Future.delayed(const Duration(milliseconds: 500));

      // Check Get.context is available before showing dialog
      if (Get.context == null) {
        debugPrint('⚠️ No context for permission dialog — skipping');
        return;
      }

      Get.dialog(
        AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'Bluetooth and Location permissions are required for printing tickets. '
            'Please enable them in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
        // Never set barrierDismissible: false at startup
        barrierDismissible: true,
      );
    }
  } catch (e) {
    // Never let permission errors block the app
    debugPrint('⚠️ Permission request error (non-fatal): $e');
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:oro_ticket_app/app/modules/utils/permission_util.dart';
import 'package:oro_ticket_app/app/routes/app_pages.dart';
import 'package:oro_ticket_app/data/locals/hive_boxes.dart';

class SplashScreenController extends GetxController {
  final String copywrite =
      "Oro Ticket App ${DateTime.now().year}. All rights reserved".tr;

  @override
  void onInit() {
    super.onInit();
    showSplash();
  }

  void showSplash() {
    // 1. Start the navigation timer immediately — do NOT await permissions
    Future.delayed(const Duration(seconds: 3), () {
      if (Get.currentRoute != Routes.SIGN_IN) {
        Get.offAllNamed(Routes.SIGN_IN);
      }
    });

    // 2. Fire-and-forget — permissions run in parallel, never block navigation
    _requestPermissionsOnFirstInstall();
  }

  Future<void> _requestPermissionsOnFirstInstall() async {
    try {
      final settingsBox = Hive.box<dynamic>(HiveBoxes.appSettingsBox);
      final permissionsRequested =
          settingsBox.get('permissionsRequested', defaultValue: false);

      if (!permissionsRequested) {
        await requestBluetoothPermissions().timeout(const Duration(seconds: 4),
            onTimeout: () {
          debugPrint('⚠️ Bluetooth permission timed out');
        });
        await settingsBox.put('permissionsRequested', true);
        debugPrint('DEBUG: Permissions requested');
      } else {
        debugPrint('DEBUG: Permissions already requested');
      }
    } catch (e) {
      debugPrint('DEBUG: Permission error (non-fatal): $e');
    }
  }
}

import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:oro_ticket_app/app/routes/app_pages.dart';
import 'package:oro_ticket_app/app/modules/utils/permission_util.dart';
import 'package:oro_ticket_app/data/locals/hive_boxes.dart';

class SplashScreenController extends GetxController {

  final String copywrite = "Oro Ticket App 2025. All rights reserved".tr;

  @override
  void onInit() {
    super.onInit();
    showSplash();
  }

  void showSplash() async {
    // Request permissions on first install
    await _requestPermissionsOnFirstInstall();
    
    Future.delayed(const Duration(seconds: 5), () {
      Get.offAllNamed(
        Routes.SIGN_IN,
      );
    });
  }

  Future<void> _requestPermissionsOnFirstInstall() async {
    try {
      final settingsBox = Hive.box<dynamic>(HiveBoxes.appSettingsBox);
      final permissionsRequested = settingsBox.get('permissionsRequested', defaultValue: false);
      
      if (!permissionsRequested) {
        // Request Bluetooth and Location permissions on first install
        await requestBluetoothPermissions();
        
        // Mark permissions as requested
        await settingsBox.put('permissionsRequested', true);
        print('DEBUG: Permissions requested on first install');
      } else {
        print('DEBUG: Permissions already requested previously');
      }
    } catch (e) {
      print('DEBUG: Error requesting permissions on first install: $e');
    }
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }
}

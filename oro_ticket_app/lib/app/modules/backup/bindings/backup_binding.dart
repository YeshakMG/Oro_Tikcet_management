import 'package:get/get.dart';
import 'package:oro_ticket_app/app/modules/backup/controllers/backup_controller.dart';

class BackupBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BackupController>(() => BackupController());
  }
}
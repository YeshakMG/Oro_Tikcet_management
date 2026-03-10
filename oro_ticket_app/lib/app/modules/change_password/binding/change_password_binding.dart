import 'package:get/get.dart';
import 'package:oro_ticket_app/app/modules/change_password/controller/change_password_controller.dart';

class ChangePasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChangePasswordController>(() => ChangePasswordController());
  }
}

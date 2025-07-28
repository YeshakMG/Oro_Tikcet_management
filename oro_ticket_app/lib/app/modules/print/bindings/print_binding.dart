import 'package:get/get.dart';
import '../controller/print_controller.dart';

class PrintBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PrintController>(() => PrintController());
  }
}
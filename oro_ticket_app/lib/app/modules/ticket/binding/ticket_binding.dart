import 'package:get/get.dart';
import '../controller/ticket_controller.dart';

class TicketBinding extends Bindings {

  @override
  void dependencies (){
    Get.lazyPut<TicketController>(() => TicketController());
    
  }
}
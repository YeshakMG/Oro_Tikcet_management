import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:get/get.dart';

class TicketPrinter {
  final printer = BlueThermalPrinter.instance;

  Future<void> connectAndPrint({
    required String text,
    required int copies,
  }) async {
    List<BluetoothDevice> devices = await printer.getBondedDevices();
    if (devices.isEmpty) {
      Get.snackbar("Printer Error", "No bonded Bluetooth printer found");
      return;
    }

    BluetoothDevice printerDevice = devices.first;

    await printer.connect(printerDevice);

    for (int i = 0; i < copies; i++) {
      await printer.printNewLine();
      await printer.printCustom(text, 1, 1); // medium text
      await printer.printNewLine();
      await printer.printNewLine();
    }

    await printer.paperCut(); // optional
    await printer.disconnect();
  }
}

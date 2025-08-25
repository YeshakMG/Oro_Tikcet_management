import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:get/get.dart';

class TicketPrinter {
  final printer = BlueThermalPrinter.instance;

  Future<void> connectAndPrint({
    required String text,
    required int copies,
    String? qrCodeData,
    String? exitText,
  }) async {
    List<BluetoothDevice> devices = await printer.getBondedDevices();
    if (devices.isEmpty) {
      Get.snackbar("Printer Error", "No bonded Bluetooth printer found");
      return;
    }

    BluetoothDevice printerDevice = devices.first;
    await printer.connect(printerDevice);

    // Print normal tickets (based on copies)
    for (int i = 0; i < copies; i++) {
      await printer.printNewLine();
      await printer.printCustom(text, 1, 0); // align left instead of center

      if (qrCodeData != null && qrCodeData.isNotEmpty) {
        await printer.printQRcode(qrCodeData, 200, 200, 1);
        await printer.printNewLine();
      }

      await printer.printNewLine();
    }

    // Print Exit Ticket (once at the end)
    if (exitText != null && exitText.isNotEmpty) {
      await printer.printNewLine();
      await printer.printCustom("EXIT TICKET", 4, 1);
      await printer.printNewLine();
      await printer.printCustom(exitText, 1, 0);
      await printer.printNewLine();
      await printer.printNewLine();
    }

    await printer.paperCut(); // optional if your printer supports
    await printer.disconnect();
  }
}

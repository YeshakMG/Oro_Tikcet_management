import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class TicketPrinter {
  final printer = BlueThermalPrinter.instance;

  Future<void> connectAndPrint({
    required String text,
    required int copies,
    String? qrCodeData,
    String? exitText,
  }) async {
    debugPrint('DEBUG: TicketPrinter.connectAndPrint called');
    debugPrint('DEBUG: Number of copies to print: $copies');
    
    // Check if already connected to the built-in printer
    final isConnected = await printer.isConnected ?? false;
    debugPrint('DEBUG: Printer isConnected: $isConnected');
    
    if (!isConnected) {
      // Get bonded devices
      List<BluetoothDevice> devices = await printer.getBondedDevices();
      debugPrint('DEBUG: Found ${devices.length} bonded devices');
      
      // Only connect if there's exactly one device (built-in printer)
      // Block connection if multiple devices found (external printers)
      if (devices.isEmpty) {
        Get.snackbar("Printer Error", "No printer found. Please pair the built-in printer in Bluetooth settings.");
        return;
      }
      
      if (devices.length > 1) {
        Get.snackbar("Printer Error", "Multiple Bluetooth devices found. Only built-in printer is allowed.");
        debugPrint('DEBUG: Blocked connection - multiple external devices detected');
        return;
      }

      // Only one device - connect to it (assumed to be built-in printer)
      BluetoothDevice printerDevice = devices.first;
      debugPrint('DEBUG: Connecting to built-in printer: ${printerDevice.name}');
      await printer.connect(printerDevice);
    }

    // Print normal tickets (based on copies)
    for (int i = 0; i < copies; i++) {
      debugPrint('DEBUG: Printing ticket ${i + 1} of $copies');
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
      debugPrint('DEBUG: Printing exit ticket');
      await printer.printNewLine();
      await printer.printCustom("EXIT TICKET", 4, 1);
      await printer.printNewLine();
      await printer.printCustom(exitText, 1, 0);
      await printer.printNewLine();
      await printer.printNewLine();
    }

    await printer.paperCut(); // optional if your printer supports
    debugPrint('DEBUG: Printing completed');
    // Keep printer connected for next print
  }
}

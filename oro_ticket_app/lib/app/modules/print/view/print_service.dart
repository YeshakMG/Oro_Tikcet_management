import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class BluetoothPrintService {
  final BlueThermalPrinter printer = BlueThermalPrinter.instance;

  Future<void> printTicket(String text) async {
    debugPrint('DEBUG: printTicket called with text: $text');
    
    // Check if already connected to the built-in printer
    final isConnected = await printer.isConnected ?? false;
    debugPrint('DEBUG: Printer isConnected: $isConnected');

    if (!isConnected) {
      // Get bonded devices
      List<BluetoothDevice> devices = await printer.getBondedDevices();
      debugPrint('DEBUG: Found bonded devices: ${devices.length}');
      
      // Only connect if there's exactly one device (built-in printer)
      // Block connection if multiple devices found (external printers)
      if (devices.isEmpty) {
        Get.snackbar("Printer Error", "No printer found. Please pair the built-in printer.");
        debugPrint('DEBUG: No printer found');
        return;
      }
      
      if (devices.length > 1) {
        Get.snackbar("Printer Error", "Multiple Bluetooth devices found. Only built-in printer is allowed.");
        debugPrint('DEBUG: Blocked connection - multiple external devices detected');
        return;
      }

      // Only one device - connect to it (assumed to be built-in printer)
      debugPrint('DEBUG: Connecting to built-in printer: ${devices.first.name}');
      await printer.connect(devices.first);
    }

    if (await printer.isConnected ?? false) {
      debugPrint('DEBUG: Starting print process...');
      printer.printNewLine();
      printer.printCustom("Oromia Ticket", 3, 1); // title, size, align
      printer.printNewLine();
      printer.printCustom(text, 1, 0); // content
      printer.printNewLine();
      printer.paperCut();
      debugPrint('DEBUG: Print completed successfully');
    } else {
      debugPrint('DEBUG: Printer not connected, cannot print');
    }
  }
}

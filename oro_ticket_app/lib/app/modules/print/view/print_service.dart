import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/foundation.dart';

class BluetoothPrintService {
  final BlueThermalPrinter printer = BlueThermalPrinter.instance;

  Future<void> printTicket(String text) async {
    debugPrint('DEBUG: printTicket called with text: $text');
    
    final isConnected = await printer.isConnected ?? false;
    debugPrint('DEBUG: Printer isConnected: $isConnected');

    if (!isConnected) {
      List<BluetoothDevice> devices = await printer.getBondedDevices();
      debugPrint('DEBUG: Found bonded devices: ${devices.length}');
      if (devices.isNotEmpty) {
        debugPrint('DEBUG: Connecting to device: ${devices.first.name}');
        await printer.connect(devices.first); // Optionally show a picker
      }
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

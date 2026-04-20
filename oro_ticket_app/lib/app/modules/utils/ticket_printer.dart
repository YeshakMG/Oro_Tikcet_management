import 'dart:convert';
import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/app/modules/ticket/model/exit_ticket_qr_model.dart';

class TicketPrinter {
  final printer = BlueThermalPrinter.instance;

  Future<void> connectAndPrint({
    required String text,
    required int copies,
    String? qrCodeData,
    String? exitText,
    ExitTicketQRData? exitQRData,
  }) async {
    try {
      List<BluetoothDevice> devices = await printer.getBondedDevices();
      if (devices.isEmpty) {
        Get.snackbar(
          "Printer Error",
          "No bonded Bluetooth printer found",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
        return;
      }

      BluetoothDevice printerDevice = devices.first;
      print('🖨️ Connecting to printer: ${printerDevice.name}');

      // Clean disconnect if already connected
      final isConnected = await printer.isConnected;
      if (isConnected == true) {
        await printer.disconnect();
        await Future.delayed(Duration(milliseconds: 500));
      }

      await printer.connect(printerDevice);
      await Future.delayed(Duration(milliseconds: 300));

      // Simple initialization - just a reset
      await _simpleInit();

      // Print normal tickets
      for (int i = 0; i < copies; i++) {
        // Print the ticket text
        await _printTextLines(text);
        await printer.printNewLine();

        // Print QR code if provided
        if (qrCodeData != null && qrCodeData.isNotEmpty) {
          await printer.printQRcode(qrCodeData, 200, 200, 1);
          await printer.printNewLine();
        }

        await printer.printNewLine();

        // Separator between multiple copies
        if (copies > 1 && i < copies - 1) {
          await _printTextLines('------------------------');
          await printer.printNewLine();
        }
      }

      // Print Exit Ticket
      if (exitText != null && exitText.isNotEmpty) {
        await printer.printNewLine();
        await printer.printNewLine();
        await _printTextLines('============================');
        await printer.printNewLine();
        await _printTextLines('      EXIT TICKET');
        await _printTextLines('============================');
        await printer.printNewLine();

        // Print exit ticket text
        await _printTextLines(exitText);
        await printer.printNewLine();

        // Print exit QR code
        if (exitQRData != null) {
          await _printTextLines('----------------------------');
          await printer.printNewLine();
          await _printTextLines('Scan for Exit Verification');
          await printer.printNewLine();

          final qrString = exitQRData.toQRString();
          await printer.printQRcode(qrString, 250, 250, 1);
          await printer.printNewLine();
          await _printTextLines('----------------------------');
        }

        await printer.printNewLine();
        await printer.printNewLine();
      }

      // Feed paper before cut
      await printer.printNewLine();
      await printer.printNewLine();
      await printer.paperCut();
      await printer.disconnect();
      print('✅ Printing completed successfully');
    } catch (e) {
      print('❌ Printer error: $e');
      Get.snackbar(
        "Printer Error",
        "Failed to print: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );

      try {
        await printer.disconnect();
      } catch (_) {}
    }
  }

  // Simple initialization - just a reset
  Future<void> _simpleInit() async {
    try {
      // Just send a reset command
      await printer.writeBytes(Uint8List.fromList([27, 64]));
      await Future.delayed(Duration(milliseconds: 100));
      print('✅ Printer reset');
    } catch (e) {
      print('⚠️ Init warning: $e');
    }
  }

  // Print text line by line to ensure all text is printed
  Future<void> _printTextLines(String text) async {
    try {
      // Split text into lines
      final lines = text.split('\n');

      for (String line in lines) {
        if (line.isEmpty) {
          await printer.printNewLine();
          continue;
        }

        // Clean the line of any problematic characters
        final cleanLine = _cleanText(line);

        if (cleanLine.isNotEmpty) {
          // Use printCustom with size 1 (normal) and align 0 (left)
          await printer.printCustom(cleanLine, 1, 0);
        } else {
          await printer.printNewLine();
        }
      }
    } catch (e) {
      print('Error printing text lines: $e');
      // Fallback: try to print raw
      try {
        await printer.printCustom(text, 1, 0);
      } catch (_) {}
    }
  }

  // Clean text of problematic characters
  String _cleanText(String input) {
    if (input.isEmpty) return input;

    // Replace Unicode box-drawing and special characters
    return input
        .replaceAll('═', '=')
        .replaceAll('║', '|')
        .replaceAll('╔', '+')
        .replaceAll('╗', '+')
        .replaceAll('╚', '+')
        .replaceAll('╝', '+')
        .replaceAll('─', '-')
        .replaceAll('•', '*')
        .replaceAll('…', '...')
        .replaceAll('════', '====')
        .replaceAll('═══', '===')
        .replaceAll('══', '==')
        // Remove any remaining non-ASCII characters
        .replaceAll(RegExp(r'[^\x20-\x7E\n\r]'), '')
        .trim();
  }

  // Method to get available printers
  Future<List<BluetoothDevice>> getAvailablePrinters() async {
    try {
      return await printer.getBondedDevices();
    } catch (e) {
      print('Error getting printers: $e');
      return [];
    }
  }

  // Method to test printer connection with a test print
  Future<bool> testPrinterConnection(BluetoothDevice device) async {
    try {
      final isConnected = await printer.isConnected;
      if (isConnected == false) {
        await printer.connect(device);
        await Future.delayed(Duration(milliseconds: 300));
      }

      // Test print
      await printer.printNewLine();
      await printer.printCustom('=== Printer Test ===', 1, 1);
      await printer.printNewLine();
      await printer.printCustom('Connection: OK', 1, 0);
      await printer.printNewLine();
      await printer.printCustom('-------------------', 1, 1);
      await printer.printNewLine();
      await printer.printNewLine();

      return true;
    } catch (e) {
      print('Printer connection test failed: $e');
      return false;
    }
  }

  // Debug method to print raw bytes
  Future<void> debugPrint() async {
    try {
      // Send raw bytes for "Hello"
      final helloBytes = Uint8List.fromList('Hello World!\n'.codeUnits);
      await printer.writeBytes(helloBytes);

      // Send line feed
      await printer.writeBytes(Uint8List.fromList([10]));

      // Cut paper
      await printer.writeBytes(Uint8List.fromList([29, 86, 66, 0]));
    } catch (e) {
      print('Debug print error: $e');
    }
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/app/modules/ticket/model/exit_ticket_qr_model.dart';

class TicketPrinter {
  final printer = BlueThermalPrinter.instance;

  Future<PrintResult> connectAndPrintVerified({
    required String text,
    required int copies,
    String? qrCodeData,
    String? exitText,
    ExitTicketQRData? exitQRData,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      print(
          '🔍 [${stopwatch.elapsedMilliseconds}ms] Getting bonded devices...');

      List<BluetoothDevice> devices;
      try {
        devices = await printer.getBondedDevices();
      } catch (e) {
        print('❌ Failed to get bonded devices: $e');
        return PrintResult(
          success: false,
          error: "Cannot access Bluetooth: ${e.toString().split('\n').first}",
        );
      }

      if (devices.isEmpty) {
        print('❌ No bonded Bluetooth devices found');
        return PrintResult(
          success: false,
          error:
              "No Bluetooth printer paired. Please pair a printer in your device settings first.",
        );
      }

      print('📱 Found ${devices.length} bonded device(s):');
      for (var device in devices) {
        print('   - ${device.name} (${device.address})');
      }

      BluetoothDevice printerDevice = devices.first;
      print(
          '🖨️ [${stopwatch.elapsedMilliseconds}ms] Selected printer: ${printerDevice.name}');

      // Check if already connected
      final wasConnected = await printer.isConnected;
      print(
          '🔌 [${stopwatch.elapsedMilliseconds}ms] Was connected: $wasConnected');

      if (wasConnected == true) {
        print('🔄 Disconnecting from existing connection...');
        try {
          await printer.disconnect();
          await Future.delayed(Duration(milliseconds: 500));
          print('✅ Disconnected successfully');
        } catch (e) {
          print('⚠️ Error disconnecting: $e');
        }
      }

      // Attempt connection with detailed retry logging
      bool connected = false;
      String? lastConnectionError;

      for (int attempt = 1; attempt <= 3; attempt++) {
        print(
            '🔗 [${stopwatch.elapsedMilliseconds}ms] Connection attempt $attempt/3...');

        try {
          await printer.connect(printerDevice).timeout(
            Duration(seconds: 5),
            onTimeout: () {
              throw Exception("Connection timeout after 5 seconds");
            },
          );

          print(
              '⏳ [${stopwatch.elapsedMilliseconds}ms] Waiting for connection to stabilize...');
          await Future.delayed(Duration(milliseconds: 800));

          // Verify connection
          final verifyConnected = await printer.isConnected;
          print(
              '🔍 [${stopwatch.elapsedMilliseconds}ms] Connection verified: $verifyConnected');

          if (verifyConnected == true) {
            connected = true;
            print('✅ Successfully connected on attempt $attempt');
            break;
          } else {
            lastConnectionError =
                "Connection reported as not connected after attempt";
            print('⚠️ Connection not verified on attempt $attempt');
          }
        } catch (e) {
          lastConnectionError = e.toString();
          print('❌ Connection attempt $attempt failed: $e');

          if (attempt < 3) {
            print('⏰ Waiting 1 second before retry...');
            await Future.delayed(Duration(seconds: 1));
          }
        }
      }

      if (!connected) {
        final errorMsg =
            "Failed to connect to ${printerDevice.name} after 3 attempts. "
            "Last error: ${lastConnectionError ?? 'Unknown'}";
        print('❌ $errorMsg');
        return PrintResult(success: false, error: errorMsg);
      }

      // Initialize printer
      print('⚙️ [${stopwatch.elapsedMilliseconds}ms] Initializing printer...');
      try {
        await _simpleInit();
        print('✅ Printer initialized');
      } catch (e) {
        print('⚠️ Init warning (continuing): $e');
      }

      // Track print success
      bool printSuccess = true;
      String? printError;
      int printedCopies = 0;

      // Print normal tickets
      print(
          '🖨️ [${stopwatch.elapsedMilliseconds}ms] Starting to print $copies copies...');

      for (int i = 0; i < copies; i++) {
        try {
          print('📄 Printing copy ${i + 1}/$copies...');

          // Print the ticket text
          await _printTextLines(text).timeout(
            Duration(seconds: 10),
            onTimeout: () {
              throw Exception("Timeout printing ticket text for copy ${i + 1}");
            },
          );

          await printer.printNewLine();

          // Print QR code if provided
          if (qrCodeData != null && qrCodeData.isNotEmpty) {
            print('🔲 Printing QR code for copy ${i + 1}...');
            await printer.printQRcode(qrCodeData, 200, 200, 1).timeout(
              Duration(seconds: 5),
              onTimeout: () {
                throw Exception("Timeout printing QR code");
              },
            );
            await printer.printNewLine();
          }

          await printer.printNewLine();

          // Separator between multiple copies
          if (copies > 1 && i < copies - 1) {
            await _printTextLines('------------------------');
            await printer.printNewLine();
          }

          printedCopies++;
          print('✅ Copy ${i + 1} printed successfully');
        } catch (e) {
          printError = "Failed to print ticket copy ${i + 1}/$copies: $e";
          print('❌ $printError');
          printSuccess = false;
          break;
        }
      }

      // Print Exit Ticket if main tickets were successful
      if (printSuccess && exitText != null && exitText.isNotEmpty) {
        print(
            '🚪 [${stopwatch.elapsedMilliseconds}ms] Printing exit ticket...');

        try {
          await printer.printNewLine();
          await printer.printNewLine();
          await _printTextLines('============================');
          await printer.printNewLine();
          await _printTextLines('      EXIT TICKET');
          await _printTextLines('============================');
          await printer.printNewLine();

          // Print exit ticket text
          await _printTextLines(exitText).timeout(
            Duration(seconds: 10),
            onTimeout: () {
              throw Exception("Timeout printing exit ticket");
            },
          );

          await printer.printNewLine();

          // Print exit QR code
          if (exitQRData != null) {
            print('🔲 Printing exit QR code...');
            await _printTextLines('----------------------------');
            await printer.printNewLine();
            await _printTextLines('Scan for Exit Verification');
            await printer.printNewLine();

            final qrString = exitQRData.toQRString();
            await printer.printQRcode(qrString, 250, 250, 1).timeout(
              Duration(seconds: 5),
              onTimeout: () {
                throw Exception("Timeout printing exit QR code");
              },
            );

            await printer.printNewLine();
            await _printTextLines('----------------------------');
          }

          await printer.printNewLine();
          await printer.printNewLine();
          print('✅ Exit ticket printed successfully');
        } catch (e) {
          printError = "Failed to print exit ticket: $e";
          print('❌ $printError');
          printSuccess = false;
        }
      }

      // Only cut paper if all printing was successful
      if (printSuccess) {
        print('✂️ [${stopwatch.elapsedMilliseconds}ms] Cutting paper...');

        try {
          await printer.printNewLine();
          await printer.printNewLine();
          await printer.paperCut().timeout(
            Duration(seconds: 3),
            onTimeout: () {
              throw Exception("Timeout during paper cut");
            },
          );

          // Verify printer still connected
          final stillConnected = await printer.isConnected;
          if (stillConnected != true) {
            printError = "Printer disconnected during finalization";
            print('❌ $printError');
            printSuccess = false;
          }

          print('✅ Paper cut successful');
        } catch (e) {
          printError = "Paper cut failed: $e";
          print('❌ $printError');
          printSuccess = false;
        }
      }

      // Disconnect
      try {
        await printer.disconnect();
        print('🔌 Printer disconnected');
      } catch (e) {
        print('⚠️ Error disconnecting: $e');
      }

      stopwatch.stop();

      if (printSuccess) {
        print(
            '✅ [${stopwatch.elapsedMilliseconds}ms] Print job completed successfully. '
            'Printed $printedCopies/$copies copies');
        return PrintResult(success: true);
      } else {
        print('❌ [${stopwatch.elapsedMilliseconds}ms] Print job failed. '
            'Printed $printedCopies/$copies copies. Error: $printError');
        return PrintResult(
          success: false,
          error: printError ?? "Print failed for unknown reason",
        );
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      print('💥 [${stopwatch.elapsedMilliseconds}ms] Fatal printer error: $e');
      print('Stack trace: $stackTrace');

      try {
        await printer.disconnect();
      } catch (_) {}

      return PrintResult(
        success: false,
        error: "Printer error: ${e.toString().split('\n').first}",
      );
    }
  }

  /*Future<void> connectAndPrint({
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
*/
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

class PrintResult {
  final bool success;
  final String? error;

  PrintResult({
    required this.success,
    this.error,
  });
}

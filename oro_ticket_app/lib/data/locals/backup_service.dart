import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:oro_ticket_app/data/locals/models/trip_model.dart';
import 'package:oro_ticket_app/data/locals/models/service_charge_model.dart';
import 'package:oro_ticket_app/data/locals/hive_boxes.dart';

class BackupService {
  /// Export unsynced trips and service charges to a JSON file
  /// Returns the file path if successful, null otherwise
  static Future<String?> exportUnsyncedData() async {
    try {
      debugPrint('🔄 Starting backup export...');
      
      final List<Map<String, dynamic>> tripsData = [];
      final List<Map<String, dynamic>> serviceChargesData = [];

      // Get unsynced trips using HiveBoxes.getBox which handles encryption
      final tripBox = await HiveBoxes.getBox<TripModel>(HiveBoxes.tripBox);
      debugPrint('📦 Trip box opened, count: ${tripBox.length}');
      
      for (var trip in tripBox.values) {
        tripsData.add(trip.toJson());
      }

      // Get all service charges
      final serviceChargeBox = await HiveBoxes.getBox<ServiceChargeModel>(HiveBoxes.serviceChargeBox);
      debugPrint('📦 Service charge box opened, count: ${serviceChargeBox.length}');
      
      for (var serviceCharge in serviceChargeBox.values) {
        serviceChargesData.add(serviceCharge.toJson());
      }

      // Create backup data
      final backupData = {
        'exportDate': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0',
        'trips': tripsData,
        'serviceCharges': serviceChargesData,
        'tripCount': tripsData.length,
        'serviceChargeCount': serviceChargesData.length,
      };

      // Generate filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'oro_backup_$timestamp.json';

      // Save to app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(backupData),
        flush: true,
      );

      debugPrint('✅ Backup saved to: ${file.path}');
      debugPrint('📊 Trips: ${tripsData.length}, Service Charges: ${serviceChargesData.length}');

      return file.path;
    } catch (e, stackTrace) {
      debugPrint('❌ Backup failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Export and share the backup file
  static Future<void> exportAndShare() async {
    try {
      debugPrint('🔄 Starting export and share...');
      
      // Show loading
      Get.dialog(
        const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Creating backup..."),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // Small delay to allow dialog to show
      await Future.delayed(const Duration(milliseconds: 100));

      final filePath = await exportUnsyncedData();

      // Close loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      if (filePath != null) {
        debugPrint('✅ Backup file created: $filePath');
        
        // Show success with option to share
        final result = await Get.dialog<bool>(
          AlertDialog(
            title: const Text("Backup Created"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Your data has been backed up successfully."),
                const SizedBox(height: 10),
                Text(
                  "File saved to app documents folder",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text("Close"),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text("Share Backup"),
              ),
            ],
          ),
        );

        if (result == true) {
          await Share.shareXFiles(
            [XFile(filePath)],
            subject: 'Oro Ticket Backup',
            text: 'Oro Ticket unsynced data backup',
          );
        }
      } else {
        Get.snackbar(
          "Error",
          "Failed to create backup. Please try again.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Export and share failed: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Close loading if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      Get.snackbar(
        "Error",
        "Backup failed: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Import data from a backup file
  static Future<int> importData(String jsonContent) async {
    try {
      final data = jsonDecode(jsonContent) as Map<String, dynamic>;
      
      int importedCount = 0;

      // Import trips
      if (data['trips'] != null) {
        final trips = (data['trips'] as List)
            .map((e) => TripModel.fromJson(e as Map<String, dynamic>))
            .toList();
        
        final tripBox = await HiveBoxes.getBox<TripModel>(HiveBoxes.tripBox);
        for (var trip in trips) {
          await tripBox.add(trip);
          importedCount++;
        }
      }

      // Import service charges
      if (data['serviceCharges'] != null) {
        final serviceCharges = (data['serviceCharges'] as List)
            .map((e) => ServiceChargeModel.fromJson(e as Map<String, dynamic>))
            .toList();
        
        final serviceChargeBox = await HiveBoxes.getBox<ServiceChargeModel>(HiveBoxes.serviceChargeBox);
        for (var serviceCharge in serviceCharges) {
          await serviceChargeBox.add(serviceCharge);
          importedCount++;
        }
      }

      debugPrint('✅ Imported $importedCount records');
      return importedCount;
    } catch (e) {
      debugPrint('❌ Import failed: $e');
      throw Exception('Invalid backup file format');
    }
  }

  /// Get count of unsynced records
  static Future<Map<String, int>> getUnsyncedCount() async {
    try {
      final tripBox = await HiveBoxes.getBox<TripModel>(HiveBoxes.tripBox);
      final serviceChargeBox = await HiveBoxes.getBox<ServiceChargeModel>(HiveBoxes.serviceChargeBox);

      return {
        'trips': tripBox.length,
        'serviceCharges': serviceChargeBox.length,
        'total': tripBox.length + serviceChargeBox.length,
      };
    } catch (e) {
      debugPrint('❌ Error getting unsynced count: $e');
      return {'trips': 0, 'serviceCharges': 0, 'total': 0};
    }
  }

  /// Check if there are unsynced records
  static Future<bool> hasUnsyncedData() async {
    final counts = await getUnsyncedCount();
    return counts['total']! > 0;
  }
}

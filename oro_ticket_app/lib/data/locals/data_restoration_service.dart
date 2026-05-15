import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:oro_ticket_app/data/locals/hive_boxes.dart';
import 'package:oro_ticket_app/data/locals/models/vehicle_model.dart';
import 'package:oro_ticket_app/data/locals/models/departure_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/models/arrival_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/models/commission_rule_model.dart';
import 'package:oro_ticket_app/data/repositories/sync_repository.dart';
import 'package:oro_ticket_app/app/modules/sign_in/services/auth_service.dart';
import 'package:oro_ticket_app/data/locals/local_backup_service.dart';

/// Service to detect and restore data when app is reinstalled or data is cleared
class DataRestorationService {
  static final DataRestorationService _instance = DataRestorationService._internal();
  factory DataRestorationService() => _instance;
  DataRestorationService._internal();

  final SyncRepository _syncRepository = SyncRepository();

  /// Key for storing initialization flag in secure storage
  static const String _dataInitializedKey = 'data_initialized_flag';

  /// Check if local data exists, if not restore from server
  /// Returns true if restoration was needed, false otherwise
  Future<bool> checkAndRestoreData() async {
    try {
      debugPrint('🔍 Checking local data integrity...');
      
      // First, check if we have a local backup with auth data
      final hasLocalBackup = await LocalBackupService.hasBackup();
      final hasAuthBackup = await LocalBackupService.hasAuthData();
      
      debugPrint('📊 Backup status:');
      debugPrint('   - Has local backup: $hasLocalBackup');
      debugPrint('   - Has auth backup: $hasAuthBackup');

      // Check if critical data exists
      final hasVehicles = await _hasVehicles();
      final hasDepartureTerminal = await _hasDepartureTerminal();
      final hasArrivalTerminals = await _hasArrivalTerminals();
      final hasCommissionRules = await _hasCommissionRules();
      
      // Check if user is logged in
      if (!Get.isRegistered<AuthService>()) {
        debugPrint('⚠️ AuthService not registered yet, skipping data integrity check');
        return false;
      }
      
      final authService = Get.find<AuthService>();
      final token = await authService.getToken();
      
      debugPrint('📊 Data status:');
      debugPrint('   - Token exists: ${token != null}');
      debugPrint('   - Vehicles: $hasVehicles');
      debugPrint('   - Departure Terminal: $hasDepartureTerminal');
      debugPrint('   - Arrival Terminals: $hasArrivalTerminals');
      debugPrint('   - Commission Rules: $hasCommissionRules');

      // If auth data is missing but we have a backup, restore auth first
      if (token == null && hasAuthBackup) {
        debugPrint('🔐 No token but auth backup exists - restoring auth first...');
        
        // Show restoration dialog
        _showRestorationDialog('Restoring your session...');

        try {
          // Restore auth data first
          final authRestored = await LocalBackupService.restoreAuthData();
          
          if (authRestored) {
            debugPrint('✅ Auth data restored successfully');
            
            // Now restore other data
            final localRestoreSuccess = await LocalBackupService.restoreFromBackup();
            
            if (localRestoreSuccess) {
              debugPrint('✅ All data restored from local backup');
            } else {
              // If local restore is partial, sync from server
              debugPrint('🔄 Syncing additional data from server...');
              await _restoreAllData();
            }
            
            // Close restoration dialog
            if (Get.isDialogOpen ?? false) {
              Get.back();
            }

            // Show success message
            Get.snackbar(
              "Welcome Back!",
              "Your session and data have been restored!",
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.green,
              colorText: Colors.white,
              duration: const Duration(seconds: 4),
            );

            debugPrint('✅ Full restoration completed successfully');
            return true;
          }
        } catch (e) {
          debugPrint('❌ Auth restoration failed: $e');
          if (Get.isDialogOpen ?? false) {
            Get.back();
          }
        }
      }

      // If token exists but other data is missing, restore from server
      if (token != null && (!hasVehicles || !hasDepartureTerminal || !hasArrivalTerminals || !hasCommissionRules)) {
        debugPrint('🔄 Missing data detected - starting auto-restore...');
        
        // Show restoration dialog
        _showRestorationDialog('Restoring data...');

        try {
          // First, try to restore from local backup (faster)
          final localRestoreSuccess = await LocalBackupService.restoreFromBackup();
          
          if (localRestoreSuccess) {
            debugPrint('✅ Data restored from local backup');
          } else {
            // If local backup fails, restore from server
            debugPrint('🔄 No local backup found, fetching from server...');
            await _restoreAllData();
          }
          
          // Close restoration dialog
          if (Get.isDialogOpen ?? false) {
            Get.back();
          }

          // Show success message
          Get.snackbar(
            "Data Restored",
            "Your data has been restored successfully!",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );

          debugPrint('✅ Data restoration completed successfully');
          return true;
        } catch (e) {
          // Close restoration dialog
          if (Get.isDialogOpen ?? false) {
            Get.back();
          }

          debugPrint('❌ Data restoration failed: $e');
          
          // Show error message
          Get.snackbar(
            "Restoration Failed",
            "Failed to restore data. Please sync manually from the Sync screen.",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
          
          return false;
        }
      }

      debugPrint('✅ All local data is intact');
      return false;
    } catch (e) {
      debugPrint('❌ Error checking data integrity: $e');
      return false;
    }
  }

  Future<bool> _hasVehicles() async {
    try {
      final box = Hive.box<VehicleModel>(HiveBoxes.vehiclesBox);
      return box.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking vehicles: $e');
      return false;
    }
  }

  Future<bool> _hasDepartureTerminal() async {
    try {
      final box = Hive.box<DepartureTerminalModel>(HiveBoxes.departureTerminalsBox);
      return box.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking departure terminal: $e');
      return false;
    }
  }

  Future<bool> _hasArrivalTerminals() async {
    try {
      final box = Hive.box<ArrivalTerminalModel>(HiveBoxes.arrivalTerminalsBox);
      return box.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking arrival terminals: $e');
      return false;
    }
  }

  Future<bool> _hasCommissionRules() async {
    try {
      final box = Hive.box<CommissionRuleModel>(HiveBoxes.commissionRulesBox);
      return box.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking commission rules: $e');
      return false;
    }
  }

  Future<void> _restoreAllData() async {
    debugPrint('🔄 Starting data restoration process...');
    
    // Restore vehicles
    debugPrint('📥 Restoring vehicles...');
    await _syncRepository.syncAllCompanyUserVehicles(forceSync: true);
    
    // Note: Departure terminal is set manually by user - cannot be fetched from server
    debugPrint('📥 Note: Departure terminal must be set manually in Departure settings');
    
    // Restore arrival terminals
    debugPrint('📥 Restoring arrival terminals...');
    await _syncRepository.syncCompanyUserArrivalTerminals();
    
    // Restore commission rules
    debugPrint('📥 Restoring commission rules...');
    await _syncRepository.syncCommissionRules();
    
    debugPrint('✅ All data restored successfully');
  }

  void _showRestorationDialog([String? message]) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(width: 16),
            Text("Restoring Data"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message ?? "Your local data appears to be missing."),
            SizedBox(height: 8),
            Text("Restoring data from backup..."),
            SizedBox(height: 16),
            LinearProgressIndicator(),
          ],
        ),
      ),
      barrierColor: Colors.black54,
    );
  }

  /// Force restore all data (can be called from UI if needed)
  Future<bool> forceRestoreData() async {
    try {
      _showRestorationDialog();

      await _restoreAllData();

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      Get.snackbar(
        "Success",
        "Data restored successfully!",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      Get.snackbar(
        "Error",
        "Failed to restore data: $e",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      
      return false;
    }
  }
}

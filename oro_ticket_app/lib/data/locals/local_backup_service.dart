import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:oro_ticket_app/data/locals/hive_boxes.dart';
import 'package:oro_ticket_app/data/locals/models/trip_model.dart';
import 'package:oro_ticket_app/data/locals/models/service_charge_model.dart';
import 'package:oro_ticket_app/data/locals/models/vehicle_model.dart';
import 'package:oro_ticket_app/data/locals/models/departure_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/models/arrival_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/models/commission_rule_model.dart';
import 'package:oro_ticket_app/data/locals/models/user_model.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service to create and restore local backup copies of data
/// This backup is stored in root external storage folder that persists
class LocalBackupService {
  static const String _backupFileName = 'backup_data.json';
  static const String _backupFolderName = '.sys_cache';
  
  // Secure storage for backup purposes
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  
  // Encryption key name in HiveBoxes
  static const String _encryptionKeyName = 'oro_ticket_encryption_key';
  
  /// Get the backup directory - uses root of external storage
  static Future<Directory?> _getBackupDirectory() async {
    if (Platform.isAndroid) {
      try {
        // Use root of external storage: /storage/emulated/0/OroTicketBackup/
        final backupDir = Directory('/storage/emulated/0/$_backupFolderName');
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }
        debugPrint('📁 Backup directory: ${backupDir.path}');
        return backupDir;
      } catch (e) {
        debugPrint('❌ Error getting backup directory: $e');
      }
    }
    
    // Fallback to app's documents directory
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${appDir.path}/backup');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }
  
  /// Request MANAGE_EXTERNAL_STORAGE permission
  static Future<bool> requestStoragePermission() async {
    // Check if we have the permission
    if (Platform.isAndroid) { 
      try {
        // On Android 11+, we need to request MANAGE_EXTERNAL_STORAGE
        // This requires the permission to be declared in manifest and user to grant it
        final status = await Permission.manageExternalStorage.status;
        debugPrint('🔐 Storage permission status: $status');
        
        if (status.isDenied) {
          debugPrint('🔐 Requesting storage permission...');
          final result = await Permission.manageExternalStorage.request();
          debugPrint('🔐 Storage permission result: $result');
          return result.isGranted;
        }
        
        if (status.isPermanentlyDenied) {
          debugPrint('⚠️ Storage permission permanently denied - opening settings');
          await openAppSettings();
          return false;
        }
        
        return status.isGranted;
      } catch (e) {
        debugPrint('❌ Error requesting storage permission: $e');
        return false;
      }
    }
    return true;
  }
  
  /// Create a backup of all critical data to external storage
  static Future<bool> createBackup() async {
    try {
      debugPrint('📦 Creating local backup...');
      
      final Map<String, dynamic> backupData = {
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'data': <String, dynamic>{},
      };

      // Backup encryption key FIRST - this is critical for restoring encrypted data
      try {
        final encryptionKey = await _secureStorage.read(key: _encryptionKeyName);
        if (encryptionKey != null && encryptionKey.isNotEmpty) {
          backupData['data']['encryptionKey'] = encryptionKey;
          debugPrint('📦 Backed up encryption key');
        }
      } catch (e) {
        debugPrint('❌ Error backing up encryption key: $e');
      }

      // Backup authentication token from secure storage
      try {
        final token = await _secureStorage.read(key: _tokenKey);
        if (token != null) {
          backupData['data']['authToken'] = token;
          debugPrint('📦 Backed up auth token');
        }
      } catch (e) {
        debugPrint('❌ Error backing up auth token: $e');
      }

      // Backup user data from Hive
      try {
        final userBox = Hive.box<UserModel>('userData');
        if (userBox.isNotEmpty) {
          final user = userBox.get('currentUser');
          if (user != null) {
            backupData['data']['user'] = user.toJson();
            debugPrint('📦 Backed up user data');
          }
        }
      } catch (e) {
        debugPrint('❌ Error backing up user data: $e');
      }

      // Backup vehicles
      try {
        final vehicleBox = await HiveBoxes.getBox<VehicleModel>(HiveBoxes.vehiclesBox);
        backupData['data']['vehicles'] = vehicleBox.values.map((v) => v.toJson()).toList();
        debugPrint('📦 Backed up ${vehicleBox.length} vehicles');
      } catch (e) {
        debugPrint('❌ Error backing up vehicles: $e');
        backupData['data']['vehicles'] = [];
      }

      // Backup departure terminals
      try {
        final departureBox = await HiveBoxes.getBox<DepartureTerminalModel>(HiveBoxes.departureTerminalsBox);
        backupData['data']['departureTerminals'] = departureBox.values.map((t) => t.toJson()).toList();
        debugPrint('📦 Backed up ${departureBox.length} departure terminals');
      } catch (e) {
        debugPrint('❌ Error backing up departure terminals: $e');
        backupData['data']['departureTerminals'] = [];
      }

      // Backup arrival terminals
      try {
        final arrivalBox = await HiveBoxes.getBox<ArrivalTerminalModel>(HiveBoxes.arrivalTerminalsBox);
        backupData['data']['arrivalTerminals'] = arrivalBox.values.map((t) => t.toJson()).toList();
        debugPrint('📦 Backed up ${arrivalBox.length} arrival terminals');
      } catch (e) {
        debugPrint('❌ Error backing up arrival terminals: $e');
        backupData['data']['arrivalTerminals'] = [];
      }

      // Backup commission rules
      try {
        final commissionBox = await HiveBoxes.getBox<CommissionRuleModel>(HiveBoxes.commissionRulesBox);
        backupData['data']['commissionRules'] = commissionBox.values.map((r) => r.toJson()).toList();
        debugPrint('📦 Backed up ${commissionBox.length} commission rules');
      } catch (e) {
        debugPrint('❌ Error backing up commission rules: $e');
        backupData['data']['commissionRules'] = [];
      }

      // Backup trips
      try {
        final tripBox = await HiveBoxes.getBox<TripModel>(HiveBoxes.tripBox);
        backupData['data']['trips'] = tripBox.values.map((t) => t.toJson()).toList();
        debugPrint('📦 Backed up ${tripBox.length} trips');
      } catch (e) {
        debugPrint('❌ Error backing up trips: $e');
        backupData['data']['trips'] = [];
      }

      // Backup service charges
      try {
        final serviceChargeBox = await HiveBoxes.getBox<ServiceChargeModel>(HiveBoxes.serviceChargeBox);
        backupData['data']['serviceCharges'] = serviceChargeBox.values.map((s) => s.toJson()).toList();
        debugPrint('📦 Backed up ${serviceChargeBox.length} service charges');
      } catch (e) {
        debugPrint('❌ Error backing up service charges: $e');
        backupData['data']['serviceCharges'] = [];
      }

      // Save to external storage (shared folder that persists)
      final directory = await _getBackupDirectory();
      if (directory == null) {
        debugPrint('❌ Backup storage not available');
        return false;
      }
      
      // Use shared backup folder
      final backupPath = '${directory.path}/$_backupFileName';
      final file = File(backupPath);
      
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(backupData),
        flush: true,
      );
      
      debugPrint('✅ Backup saved to: $backupPath');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Backup creation failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Restore data from local backup
  /// Returns true if restoration was successful
  static Future<bool> restoreFromBackup() async {
    try {
      debugPrint('🔄 Checking for local backup...');
      
      // Use the backup directory
      final directory = await _getBackupDirectory();
      if (directory == null) {
        debugPrint('❌ Backup storage not available');
        return false;
      }
      
      final backupPath = '${directory.path}/$_backupFileName';
      final file = File(backupPath);
      
      if (!await file.exists()) {
        debugPrint('ℹ️ No backup file found');
        return false;
      }

      final jsonContent = await file.readAsString();
      final backupData = jsonDecode(jsonContent) as Map<String, dynamic>;
      
      debugPrint('📥 Found backup from: ${backupData['timestamp']}');
      
      // Check what's in the backup
      final vehicles = backupData['data']['vehicles'] as List?;
      final departureTerminals = backupData['data']['departureTerminals'] as List?;
      final arrivalTerminals = backupData['data']['arrivalTerminals'] as List?;
      final commissionRules = backupData['data']['commissionRules'] as List?;
      
      debugPrint('📋 Backup contents: vehicles=${vehicles?.length ?? 0}, departureTerminals=${departureTerminals?.length ?? 0}, arrivalTerminals=${arrivalTerminals?.length ?? 0}, commissionRules=${commissionRules?.length ?? 0}');
      
      int restoredCount = 0;

      // First restore auth token and user (if present)
      bool authRestored = false;
      if (backupData['data']['authToken'] != null || backupData['data']['user'] != null) {
        authRestored = await _restoreAuthData(backupData);
        if (authRestored) {
          restoredCount++;
        }
      }

      // Restore vehicles
      if (backupData['data']['vehicles'] != null) {
        try {
          final vehiclesList = (backupData['data']['vehicles'] as List)
              .map((v) => VehicleModel.fromJson(v as Map<String, dynamic>))
              .toList();
          
          if (vehiclesList.isNotEmpty) {
            final vehicleBox = await HiveBoxes.getBox<VehicleModel>(HiveBoxes.vehiclesBox);
            await vehicleBox.clear();
            for (final vehicle in vehiclesList) {
              try {
                await vehicleBox.add(vehicle);
              } catch (e) {
                debugPrint('❌ Error adding vehicle: $e');
              }
            }
            restoredCount += vehiclesList.length;
            debugPrint('✅ Restored ${vehiclesList.length} vehicles');
          }
        } catch (e) {
          debugPrint('❌ Error restoring vehicles: $e');
        }
      }

      // Restore departure terminals
      if (backupData['data']['departureTerminals'] != null) {
        try {
          final terminalsList = (backupData['data']['departureTerminals'] as List)
              .map((t) => DepartureTerminalModel.fromJson(t as Map<String, dynamic>))
              .toList();
          
          debugPrint('🔍 Departure terminals in backup: ${terminalsList.length}');
          for (var t in terminalsList) {
            debugPrint('🔍 Terminal: ${t.toJson()}');
          }
          
          if (terminalsList.isNotEmpty) {
            final terminalBox = await HiveBoxes.getBox<DepartureTerminalModel>(HiveBoxes.departureTerminalsBox);
            await terminalBox.clear();
            for (final terminal in terminalsList) {
              try {
                await terminalBox.add(terminal);
              } catch (e) {
                debugPrint('❌ Error adding departure terminal: $e');
              }
            }
            restoredCount += terminalsList.length;
            debugPrint('✅ Restored ${terminalsList.length} departure terminals');
          } else {
            debugPrint('⚠️ Departure terminals list is empty in backup');
          }
        } catch (e) {
          debugPrint('❌ Error restoring departure terminals: $e');
        }
      } else {
        debugPrint('⚠️ No departure terminals key found in backup data');
      }

      // Restore arrival terminals
      if (backupData['data']['arrivalTerminals'] != null) {
        final terminals = (backupData['data']['arrivalTerminals'] as List)
            .map((t) => ArrivalTerminalModel.fromJson(t as Map<String, dynamic>))
            .toList();
        
        if (terminals.isNotEmpty) {
          final arrivalBox = await HiveBoxes.getBox<ArrivalTerminalModel>(HiveBoxes.arrivalTerminalsBox);
          await arrivalBox.clear();
          for (final terminal in terminals) {
            await arrivalBox.add(terminal);
          }
          restoredCount += terminals.length;
          debugPrint('✅ Restored ${terminals.length} arrival terminals');
        }
      }

      // Restore commission rules
      if (backupData['data']['commissionRules'] != null) {
        final rules = (backupData['data']['commissionRules'] as List)
            .map((r) => CommissionRuleModel.fromJson(r as Map<String, dynamic>))
            .toList();
        
        if (rules.isNotEmpty) {
          final commissionBox = await HiveBoxes.getBox<CommissionRuleModel>(HiveBoxes.commissionRulesBox);
          await commissionBox.clear();
          for (final rule in rules) {
            await commissionBox.add(rule);
          }
          restoredCount += rules.length;
          debugPrint('✅ Restored ${rules.length} commission rules');
        }
      }

      // Restore trips
      if (backupData['data']['trips'] != null) {
        final trips = (backupData['data']['trips'] as List)
            .map((t) => TripModel.fromJson(t as Map<String, dynamic>))
            .toList();
        
        if (trips.isNotEmpty) {
          final tripBox = await HiveBoxes.getBox<TripModel>(HiveBoxes.tripBox);
          await tripBox.clear();
          for (final trip in trips) {
            await tripBox.add(trip);
          }
          restoredCount += trips.length;
          debugPrint('✅ Restored ${trips.length} trips');
        }
      }

      // Restore service charges
      if (backupData['data']['serviceCharges'] != null) {
        final serviceCharges = (backupData['data']['serviceCharges'] as List)
            .map((s) => ServiceChargeModel.fromJson(s as Map<String, dynamic>))
            .toList();
        
        if (serviceCharges.isNotEmpty) {
          final serviceChargeBox = await HiveBoxes.getBox<ServiceChargeModel>(HiveBoxes.serviceChargeBox);
          await serviceChargeBox.clear();
          for (final serviceCharge in serviceCharges) {
            await serviceChargeBox.add(serviceCharge);
          }
          restoredCount += serviceCharges.length;
          debugPrint('✅ Restored ${serviceCharges.length} service charges');
        }
      }

      debugPrint('✅ Total restored: $restoredCount records');
      return restoredCount > 0;
    } catch (e, stackTrace) {
      debugPrint('❌ Backup restoration failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Check if backup exists
  static Future<bool> hasBackup() async {
    try {
      final directory = await _getBackupDirectory();
      if (directory == null) return false;
      
      final backupPath = '${directory.path}/$_backupFileName';
      final file = File(backupPath);
      
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Delete the backup file
  static Future<bool> deleteBackup() async {
    try {
      final directory = await _getBackupDirectory();
      if (directory == null) return false;
      
      final backupPath = '${directory.path}/$_backupFileName';
      final file = File(backupPath);
      
      if (await file.exists()) {
        await file.delete();
        debugPrint('🗑️ Backup deleted');
      }
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting backup: $e');
      return false;
    }
  }
  
  /// Check if backup has auth token
  static Future<bool> hasAuthData() async {
    try {
      final directory = await _getBackupDirectory();
      if (directory == null) {
        debugPrint('❌ Backup directory not available');
        return false;
      }
      
      final backupPath = '${directory.path}/$_backupFileName';
      final file = File(backupPath);
      
      if (!await file.exists()) {
        debugPrint('❌ Backup file does not exist');
        return false;
      }
      
      final jsonContent = await file.readAsString();
      final backupData = jsonDecode(jsonContent) as Map<String, dynamic>;
      
      final hasToken = backupData['data']['authToken'] != null;
      final hasUser = backupData['data']['user'] != null;
      final hasEncryptionKey = backupData['data']['encryptionKey'] != null;
      
      debugPrint('📋 Backup check - Token: $hasToken, User: $hasUser, EncryptionKey: $hasEncryptionKey');
      
      return hasToken || hasUser || hasEncryptionKey;
    } catch (e) {
      debugPrint('❌ Error checking auth data: $e');
      return false;
    }
  }
  
  /// Restore auth token and user data from backup
  /// This should be called BEFORE restoring other data
  static Future<bool> restoreAuthData() async {
    try {
      debugPrint('🔐 Restoring auth data from backup...');
      
      final directory = await _getBackupDirectory();
      if (directory == null) {
        debugPrint('❌ Backup storage not available');
        return false;
      }
      
      final backupPath = '${directory.path}/$_backupFileName';
      final file = File(backupPath);
      
      if (!await file.exists()) {
        debugPrint('ℹ️ No backup file found');
        return false;
      }

      final jsonContent = await file.readAsString();
      final backupData = jsonDecode(jsonContent) as Map<String, dynamic>;
      
      return await _restoreAuthData(backupData);
    } catch (e, stackTrace) {
      debugPrint('❌ Auth data restoration failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }
  
  /// Internal method to restore auth data
  static Future<bool> _restoreAuthData(Map<String, dynamic> backupData) async {
    try {
      bool restored = false;
      
      // FIRST: Restore encryption key - this is critical for encrypted Hive boxes
      if (backupData['data']['encryptionKey'] != null) {
        final encryptionKey = backupData['data']['encryptionKey'] as String;
        await _secureStorage.write(key: _encryptionKeyName, value: encryptionKey);
        // Reset the cached key so it re-reads from secure storage
        HiveBoxes.resetEncryptionKey();
        // Re-open boxes with restored key so they can decrypt the backup data
        await HiveBoxes.reOpenBoxesWithRestoredKey();
        debugPrint('✅ Restored encryption key and re-opened boxes');
      }
      
      // Restore auth token to secure storage
      if (backupData['data']['authToken'] != null) {
        final token = backupData['data']['authToken'] as String;
        await _secureStorage.write(key: _tokenKey, value: token);
        debugPrint('✅ Restored auth token');
        restored = true;
      }
      
      // Restore user data to Hive
      if (backupData['data']['user'] != null) {
        final userJson = backupData['data']['user'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userJson);
        
        final userBox = Hive.box<UserModel>('userData');
        await userBox.put('currentUser', user);
        debugPrint('✅ Restored user data');
        restored = true;
      }
      
      return restored;
    } catch (e) {
      debugPrint('❌ Error restoring auth data: $e');
      return false;
    }
  }
}

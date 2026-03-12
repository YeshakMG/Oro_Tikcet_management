import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:oro_ticket_app/data/locals/models/arrival_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/models/commission_rule_model.dart';
import 'package:oro_ticket_app/data/locals/models/departure_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/models/service_charge_model.dart';
import 'package:oro_ticket_app/data/locals/models/trip_model.dart';
import 'package:oro_ticket_app/data/locals/models/user_model.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import 'models/vehicle_model.dart';

class HiveBoxes {
  static const String vehiclesBox = 'vehiclesBox';
  static const String departureTerminalsBox = 'departureTerminalsBox';
  static const String arrivalTerminalsBox = 'arrivalTerminalsBox';
  static const String commissionRulesBox = 'commissionRulesBox';
  static const String tripBox = 'tripBox';
  static const String serviceChargeBox = 'serviceChargeBox';
  static const String userBox = 'userData';
  
  // Encryption key name in secure storage
  static const String encryptionKeyName = 'oro_ticket_encryption_key';
  
  static bool _initialized = false;
  static List<int>? _encryptionKey;
  
  // Secure storage instance
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Generates or retrieves the encryption key from secure storage
  static Future<List<int>> _getEncryptionKey() async {
    if (_encryptionKey != null) {
      return _encryptionKey!;
    }

    try {
      // Try to get existing key from secure storage
      final keyString = await _secureStorage.read(key: encryptionKeyName);
      
      if (keyString != null && keyString.isNotEmpty) {
        // Decode existing key
        _encryptionKey = keyString.split(',').map((e) => int.parse(e)).toList();
      } else {
        // Generate new 256-bit key
        _encryptionKey = Hive.generateSecureKey();
        
        // Store the key securely
        await _secureStorage.write(
          key: encryptionKeyName, 
          value: _encryptionKey!.join(',')
        );
        
        debugPrint('✅ New encryption key generated and stored securely');
      }
      
      return _encryptionKey!;
    } catch (e) {
      debugPrint('Error getting encryption key: $e');
      // Fallback: generate a key (won't persist if secure storage fails)
      _encryptionKey = Hive.generateSecureKey();
      return _encryptionKey!;
    }
  }

  static Future<void> init() async {
    if (_initialized) return;

    try {
      final appDir = await path_provider.getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDir.path);

      // Get encryption key from secure storage
      final encryptionKey = await _getEncryptionKey();
      
      // Create AES-256 encryption cipher
      final cipher = HiveAesCipher(encryptionKey);

      // Register adapters
      Hive.registerAdapter(VehicleModelAdapter());
      Hive.registerAdapter(DepartureTerminalModelAdapter());
      Hive.registerAdapter(ArrivalTerminalModelAdapter());
      Hive.registerAdapter(CommissionRuleModelAdapter());
      Hive.registerAdapter(TripModelAdapter());
      Hive.registerAdapter(ServiceChargeModelAdapter());
      Hive.registerAdapter(UserModelAdapter());
      Hive.registerAdapter(LevelSpecificTariffAdapter());

      // Open encrypted boxes with AES-256 encryption
      await Future.wait([
        Hive.openBox<VehicleModel>(
          vehiclesBox,
          encryptionCipher: cipher,
        ),
        Hive.openBox<DepartureTerminalModel>(
          departureTerminalsBox,
          encryptionCipher: cipher,
        ),
        Hive.openBox<ArrivalTerminalModel>(
          arrivalTerminalsBox,
          encryptionCipher: cipher,
        ),
        Hive.openBox<CommissionRuleModel>(
          commissionRulesBox,
          encryptionCipher: cipher,
        ),
        Hive.openBox<TripModel>(
          tripBox,
          encryptionCipher: cipher,
        ),
        Hive.openBox<ServiceChargeModel>(
          serviceChargeBox,
          encryptionCipher: cipher,
        ),
        // User box remains unencrypted for easy access
        Hive.openBox<UserModel>(userBox),
      ]);

      _initialized = true;
      
      debugPrint('✅ All data boxes initialized with AES-256 encryption');
    } catch (e) {
      debugPrint('Hive initialization failed: $e');
      rethrow;
    }
  }

  static Future<void> _deleteBoxIfExists(String boxName) async {
    if (await Hive.boxExists(boxName)) {
      await Hive.deleteBoxFromDisk(boxName);
    }
  }

  static Future<Box<T>> getBox<T>(String boxName) async {
    if (!_initialized) await init();
    if (!Hive.isBoxOpen(boxName)) {
      // Get encryption key from secure storage
      final encryptionKey = await _getEncryptionKey();
      final cipher = HiveAesCipher(encryptionKey);
      
      // Check if this is an encrypted box type
      if (boxName == vehiclesBox || 
          boxName == departureTerminalsBox || 
          boxName == arrivalTerminalsBox ||
          boxName == commissionRulesBox ||
          boxName == tripBox ||
          boxName == serviceChargeBox) {
        return await Hive.openBox<T>(boxName, encryptionCipher: cipher);
      }
      return await Hive.openBox<T>(boxName);
    }
    return Hive.box<T>(boxName);
  }
  
  /// Method to clear all encrypted data (for logout or reset)
  static Future<void> clearAllData() async {
    try {
      await Future.wait([
        Hive.box<VehicleModel>(vehiclesBox).clear(),
        Hive.box<DepartureTerminalModel>(departureTerminalsBox).clear(),
        Hive.box<ArrivalTerminalModel>(arrivalTerminalsBox).clear(),
        Hive.box<CommissionRuleModel>(commissionRulesBox).clear(),
        Hive.box<TripModel>(tripBox).clear(),
        Hive.box<ServiceChargeModel>(serviceChargeBox).clear(),
        Hive.box<UserModel>(userBox).clear(),
      ]);
      
      // Clear the encryption key from secure storage
      await _secureStorage.delete(key: encryptionKeyName);
      _encryptionKey = null;
      
      debugPrint('✅ All encrypted data cleared');
    } catch (e) {
      debugPrint('Error clearing data: $e');
    }
  }
}

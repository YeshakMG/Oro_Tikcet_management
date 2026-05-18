import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:oro_ticket_app/data/locals/models/arrival_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/models/commission_rule_model.dart';
import 'package:oro_ticket_app/data/locals/models/departure_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/models/service_charge_model.dart';
import 'package:oro_ticket_app/data/locals/models/tariff_model.dart';
import 'package:oro_ticket_app/data/locals/models/terminal_destination.dart';
import 'package:oro_ticket_app/data/locals/models/trip_model.dart';
import 'package:oro_ticket_app/data/locals/models/user_model.dart';
import 'package:oro_ticket_app/data/locals/models/vehicle_print_lock_model.dart';
import 'package:oro_ticket_app/data/locals/models/vehicle_route.dart';
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
  static const String tariffsBox = 'tariffsBox';
  static const String vehiclePrintLockBox = 'vehiclePrintLocksBox';
  static const String lastUsedVehicleBox = 'lastUsedVehicleBox';
  static const String appSettingsBox = 'appSettingsBox';

  static bool _initialized = false;
  static const String encryptionKeyName = 'oro_ticket_encryption_key';
  static List<int>? _encryptionKey;

  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<List<int>> _getEncryptionKey() async {
    if (_encryptionKey != null) return _encryptionKey!;

    try {
      final keyString = await _secureStorage.read(key: encryptionKeyName);
      if (keyString != null && keyString.isNotEmpty) {
        _encryptionKey = keyString.split(',').map((e) => int.parse(e)).toList();
      } else {
        _encryptionKey = Hive.generateSecureKey();
        await _secureStorage.write(
          key: encryptionKeyName,
          value: _encryptionKey!.join(','),
        );
        debugPrint('✅ New encryption key generated and stored');
      }
      return _encryptionKey!;
    } catch (e) {
      debugPrint('❌ Error getting encryption key: $e');
      _encryptionKey = Hive.generateSecureKey();
      return _encryptionKey!;
    }
  }

  static Future<void> init() async {
    if (_initialized) return;

    try {
      final appDir = await path_provider.getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDir.path);

      // Register all adapters BEFORE opening any box
      _registerAdapters();

      // Get encryption key once
      final encryptionKey = await _getEncryptionKey();
      final cipher = HiveAesCipher(encryptionKey);

      // Open ALL boxes ONCE — encrypted boxes with cipher, others without
      await Future.wait([
        // Unencrypted boxes
        Hive.openBox('appState'),
        Hive.openBox<UserModel>(userBox), // unencrypted for easy access
        Hive.openBox<dynamic>(lastUsedVehicleBox),
        Hive.openBox<dynamic>(appSettingsBox),

        // Encrypted boxes — opened ONCE with cipher
        Hive.openBox<VehicleModel>(vehiclesBox, encryptionCipher: cipher),
        Hive.openBox<DepartureTerminalModel>(departureTerminalsBox,
            encryptionCipher: cipher),
        Hive.openBox<ArrivalTerminalModel>(arrivalTerminalsBox,
            encryptionCipher: cipher),
        Hive.openBox<CommissionRuleModel>(commissionRulesBox,
            encryptionCipher: cipher),
        Hive.openBox<TripModel>(tripBox, encryptionCipher: cipher),
        Hive.openBox<ServiceChargeModel>(serviceChargeBox,
            encryptionCipher: cipher),
        Hive.openBox<TariffModel>(tariffsBox, encryptionCipher: cipher),
        Hive.openBox<VehiclePrintLock>(vehiclePrintLockBox,
            encryptionCipher: cipher),
      ]);

      debugPrint('✅ All data boxes initialized with AES-256 encryption');
      _initialized = true;
    } catch (e) {
      debugPrint('❌ Hive initialization failed: $e');
      rethrow;
    }
  }

  static void _registerAdapters() {
    // Guard each registration so hot-restart doesn't throw "already registered"
    if (!Hive.isAdapterRegistered(VehicleModelAdapter().typeId)) {
      Hive.registerAdapter(VehicleModelAdapter());
    }
    if (!Hive.isAdapterRegistered(DepartureTerminalModelAdapter().typeId)) {
      Hive.registerAdapter(DepartureTerminalModelAdapter());
    }
    if (!Hive.isAdapterRegistered(ArrivalTerminalModelAdapter().typeId)) {
      Hive.registerAdapter(ArrivalTerminalModelAdapter());
    }
    if (!Hive.isAdapterRegistered(CommissionRuleModelAdapter().typeId)) {
      Hive.registerAdapter(CommissionRuleModelAdapter());
    }
    if (!Hive.isAdapterRegistered(TripModelAdapter().typeId)) {
      Hive.registerAdapter(TripModelAdapter());
    }
    if (!Hive.isAdapterRegistered(ServiceChargeModelAdapter().typeId)) {
      Hive.registerAdapter(ServiceChargeModelAdapter());
    }
    if (!Hive.isAdapterRegistered(UserModelAdapter().typeId)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(TariffModelAdapter().typeId)) {
      Hive.registerAdapter(TariffModelAdapter());
    }
    if (!Hive.isAdapterRegistered(TerminalDestinationAdapter().typeId)) {
      Hive.registerAdapter(TerminalDestinationAdapter());
    }
    if (!Hive.isAdapterRegistered(VehicleRouteAdapter().typeId)) {
      Hive.registerAdapter(VehicleRouteAdapter());
    }
    if (!Hive.isAdapterRegistered(VehiclePrintLockAdapter().typeId)) {
      Hive.registerAdapter(VehiclePrintLockAdapter());
    }
  }

  static Future<Box<T>> getBox<T>(String boxName) async {
    if (!_initialized) await init();
    if (Hive.isBoxOpen(boxName)) return Hive.box<T>(boxName);

    // Box was closed unexpectedly — re-open it
    final encryptionKey = await _getEncryptionKey();
    final cipher = HiveAesCipher(encryptionKey);

    const encryptedBoxes = {
      vehiclesBox,
      departureTerminalsBox,
      arrivalTerminalsBox,
      commissionRulesBox,
      tripBox,
      serviceChargeBox,
      tariffsBox,
      vehiclePrintLockBox,
    };

    if (encryptedBoxes.contains(boxName)) {
      return Hive.openBox<T>(boxName, encryptionCipher: cipher);
    }
    return Hive.openBox<T>(boxName);
  }

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
        Hive.box<dynamic>(lastUsedVehicleBox).clear(),
        Hive.box<dynamic>(appSettingsBox).clear(),
        Hive.box<TariffModel>(tariffsBox).clear(),
        Hive.box<VehiclePrintLock>(vehiclePrintLockBox).clear(),
      ]);
      await _secureStorage.delete(key: encryptionKeyName);
      _encryptionKey = null;
      debugPrint('✅ All data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing data: $e');
    }
  }

  static Future<void> clearAuthData() async {
    try {
      await Future.wait([
        Hive.box<VehicleModel>(vehiclesBox).clear(),
        Hive.box<DepartureTerminalModel>(departureTerminalsBox).clear(),
        Hive.box<ArrivalTerminalModel>(arrivalTerminalsBox).clear(),
        Hive.box<CommissionRuleModel>(commissionRulesBox).clear(),
        Hive.box<UserModel>(userBox).clear(),
        Hive.box<dynamic>(lastUsedVehicleBox).clear(),
        Hive.box<dynamic>(appSettingsBox).clear(),
        Hive.box<TariffModel>(tariffsBox).clear(),
        Hive.box<VehiclePrintLock>(vehiclePrintLockBox).clear(),
      ]);
      debugPrint('✅ Auth data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing auth data: $e');
    }
  }

  static void resetEncryptionKey() {
    _encryptionKey = null;
    debugPrint('🔑 Encryption key cache reset');
  }

  // Removed reOpenBoxesWithRestoredKey() entirely — it was causing double-open hangs.
  // The restored encryption key in secure storage will be picked up automatically
  // on the next cold start via _getEncryptionKey().
}

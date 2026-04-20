// data/locals/service/tariff_storage_service.dart
import 'package:hive/hive.dart';
import 'package:oro_ticket_app/data/locals/hive_boxes.dart';
import 'package:oro_ticket_app/data/locals/models/tariff_model.dart';

class TariffStorageService {
  static Future<void> saveTariffs(List<TariffModel> tariffs) async {
    final box = await HiveBoxes.getBox<TariffModel>(HiveBoxes.tariffsBox);
    await box.clear();

    int validCount = 0;
    for (final tariff in tariffs) {
      if (tariff.isValid()) {
        await box.put(tariff.id, tariff);
        validCount++;
      } else {
        print('⚠️ Skipping invalid tariff: $tariff');
      }
    }
    print('✅ Saved $validCount valid tariffs out of ${tariffs.length} total');
  }

  static List<TariffModel> getValidTariffs() {
    final box = Hive.box<TariffModel>(HiveBoxes.tariffsBox);
    return box.values.where((t) => t.isValid()).toList();
  }

  // In TariffStorageService, improve the query method:
  static TariffModel? getTariffByVehicleLevelAndRoadType(
    String vehicleLevelId,
    String roadType, {
    String? terminalDestinationId,
    String? fleetTypeId,
  }) {
    final box = Hive.box<TariffModel>(HiveBoxes.tariffsBox);
    final allTariffs = box.values.toList();

    print('🔍 Searching tariff for:');
    print('   Vehicle Level: $vehicleLevelId');
    print('   Road Type: $roadType');
    print('   Terminal Dest: $terminalDestinationId');
    print('   Fleet Type: $fleetTypeId');
    print('   Total tariffs in box: ${allTariffs.length}');

    // First, find ALL tariffs matching vehicle level and road type (for debugging)
    final matchingLevelAndRoad = allTariffs
        .where((t) =>
            t.vehicleLevelId == vehicleLevelId &&
            t.roadType == roadType &&
            t.deletedAt == null)
        .toList();

    print(
        '📋 Found ${matchingLevelAndRoad.length} tariffs matching level and road type:');
    for (var t in matchingLevelAndRoad) {
      print(
          '   - ID: ${t.id}, Price: ${t.pricePerKm}, Valid: ${t.isValid()}, Terminal: ${t.terminalDestinationId}');
    }

    // Try specific tariff first
    if (terminalDestinationId != null && fleetTypeId != null) {
      try {
        final specificTariff = allTariffs.firstWhere(
          (t) =>
              t.vehicleLevelId == vehicleLevelId &&
              t.roadType == roadType &&
              t.terminalDestinationId == terminalDestinationId &&
              t.fleetTypeId == fleetTypeId &&
              t.deletedAt == null &&
              t.isValid(),
        );
        print(
            '✅ Found specific tariff: ${specificTariff.id} with price ${specificTariff.pricePerKm}');
        return specificTariff;
      } catch (e) {
        print('ℹ️ No specific tariff found with terminal and fleet');
      }
    }

    // Try general tariff (no terminal destination)
    try {
      final generalTariff = allTariffs.firstWhere(
        (t) =>
            t.vehicleLevelId == vehicleLevelId &&
            t.roadType == roadType &&
            t.terminalDestinationId == null &&
            t.deletedAt == null &&
            t.isValid(),
      );
      print(
          '✅ Found general tariff: ${generalTariff.id} with price ${generalTariff.pricePerKm}');
      return generalTariff;
    } catch (e) {
      print('ℹ️ No general tariff found');
    }

    // Last resort: any tariff matching level and road type
    if (matchingLevelAndRoad.isNotEmpty) {
      final anyTariff = matchingLevelAndRoad.firstWhere(
        (t) => t.isValid(),
        orElse: () => matchingLevelAndRoad.first,
      );
      print(
          '⚠️ Using fallback tariff: ${anyTariff.id} with price ${anyTariff.pricePerKm}');
      return anyTariff;
    }

    print(
        '❌ No tariff found for vehicle level: $vehicleLevelId, road type: $roadType');
    return null;
  }

  // In TariffStorageService, add this debug method:
  static void debugPrintAllTariffs() {
    final box = Hive.box<TariffModel>(HiveBoxes.tariffsBox);
    final tariffs = box.values.toList();

    print('📊 ALL TARIFFS IN STORAGE (${tariffs.length}):');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    for (var t in tariffs) {
      print('''
ID: ${t.id}
  Vehicle Level ID: ${t.vehicleLevelId}
  Vehicle Level Name: ${t.vehicleLevelName}
  Road Type: ${t.roadType}
  Price per KM: ${t.pricePerKm}
  Terminal Dest ID: ${t.terminalDestinationId}
  Fleet Type ID: ${t.fleetTypeId}
  Valid: ${t.isValid()}
  Deleted: ${t.deletedAt != null}
  ────────────────────────────────────
''');
    }

    // Also show tariffs for your specific vehicle level
    final levelTariffs = tariffs
        .where(
            (t) => t.vehicleLevelId == '9ceffd5b-a75c-46a6-82d6-8e057e6086c9')
        .toList();

    print('🎯 Tariffs for Level 1 (9ceffd5b...): ${levelTariffs.length}');
    for (var t in levelTariffs) {
      print(
          '  - Road: ${t.roadType}, Price: ${t.pricePerKm}, Valid: ${t.isValid()}');
    }
  }

  static Map<String, List<TariffModel>> getTariffsGroupedByVehicleLevel() {
    final tariffs = getValidTariffs();
    final Map<String, List<TariffModel>> grouped = {};

    for (var tariff in tariffs) {
      grouped.putIfAbsent(tariff.vehicleLevelId, () => []).add(tariff);
    }

    return grouped;
  }

  static void clearTariffs() {
    final box = Hive.box<TariffModel>(HiveBoxes.tariffsBox);
    box.clear();
  }
}

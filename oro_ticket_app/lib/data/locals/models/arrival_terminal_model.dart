import 'package:hive/hive.dart';

part 'arrival_terminal_model.g.dart';

// Model for level-specific tariff
@HiveType(typeId: 8)
class LevelSpecificTariff {
  @HiveField(0)
  final String vehicleLevelId;
  
  @HiveField(1)
  final String vehicleLevelName;
  
  @HiveField(2)
  final String fleetTypeId;
  
  @HiveField(3)
  final String fleetTypeName;
  
  @HiveField(4)
  final double tariff;

  LevelSpecificTariff({
    required this.vehicleLevelId,
    required this.vehicleLevelName,
    required this.fleetTypeId,
    required this.fleetTypeName,
    required this.tariff,
  });

  factory LevelSpecificTariff.fromJson(Map<String, dynamic> json) {
    return LevelSpecificTariff(
      vehicleLevelId: json['vehicle_level_id'] ?? '',
      vehicleLevelName: json['vehicle_level_name'] ?? '',
      fleetTypeId: json['fleet_type_id'] ?? '',
      fleetTypeName: json['fleet_type_name'] ?? '',
      tariff: _parseDouble(json['tariff']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() => {
    'vehicle_level_id': vehicleLevelId,
    'vehicle_level_name': vehicleLevelName,
    'fleet_type_id': fleetTypeId,
    'fleet_type_name': fleetTypeName,
    'tariff': tariff,
  };
}

@HiveType(typeId: 3)
class ArrivalTerminalModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double tariff;

  @HiveField(3)
  final double distance;
  
  // Level-based tariffs
  @HiveField(4)
  final double? tariffLevel1; // Legacy field
  
  @HiveField(5)
  final double? tariffLevel2; // Legacy field
  
  @HiveField(6)
  final double? tariffLevel3; // Legacy field

  // Level-based tariffs from API array (new format)
  @HiveField(7)
  final List<LevelSpecificTariff>? levelSpecificTariffs;

  ArrivalTerminalModel({
    required this.id,
    required this.name,
    required this.tariff,
    required this.distance,
    this.tariffLevel1,
    this.tariffLevel2,
    this.tariffLevel3,
    this.levelSpecificTariffs,
  });

  factory ArrivalTerminalModel.fromJson(Map<String, dynamic> json) {
    dynamic tariffValue = json['tariff'];
    double parsedTariff = 0.0;
    
    if (tariffValue != null) {
      if (tariffValue is String) {
        parsedTariff = double.tryParse(tariffValue) ?? 0.0;
      } else if (tariffValue is int) {
        parsedTariff = tariffValue.toDouble();
      } else if (tariffValue is double) {
        parsedTariff = tariffValue;
      }
    }

    // Handle distance conversion
    dynamic distanceValue = json['distance'];
    double parsedDistance = 0.0;
    
    if (distanceValue != null) {
      if (distanceValue is String) {
        parsedDistance = double.tryParse(distanceValue) ?? 0.0;
      } else if (distanceValue is int) {
        parsedDistance = distanceValue.toDouble();
      } else if (distanceValue is double) {
        parsedDistance = distanceValue;
      }
    }
    
    // Handle level-specific tariffs from API array
    List<LevelSpecificTariff>? parsedLevelTariffs;
    if (json['level_specific_tariffs'] is List) {
      parsedLevelTariffs = (json['level_specific_tariffs'] as List)
          .map((e) => LevelSpecificTariff.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    
    // Helper function to parse tariff
    double? parseTariff(dynamic value) {
      if (value == null) return null;
      if (value is String) return double.tryParse(value);
      if (value is int) return value.toDouble();
      if (value is double) return value;
      return null;
    }
    
    // Also check for legacy flat fields (for backward compatibility)
    double? tariffLevel1 = parseTariff(json['tariff_level1']);
    double? tariffLevel2 = parseTariff(json['tariff_level2']);
    double? tariffLevel3 = parseTariff(json['tariff_level3']);

    return ArrivalTerminalModel(
      id: json['id'] ?? json['arrival_terminal_id'] ?? '',
      name: json['name'] ?? '',
      tariff: parsedTariff,
      distance: parsedDistance,
      tariffLevel1: tariffLevel1,
      tariffLevel2: tariffLevel2,
      tariffLevel3: tariffLevel3,
      levelSpecificTariffs: parsedLevelTariffs,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tariff': tariff.toString(),
        'distance': distance.toString(),
        'tariff_level1': tariffLevel1?.toString(),
        'tariff_level2': tariffLevel2?.toString(),
        'tariff_level3': tariffLevel3?.toString(),
        'level_specific_tariffs': levelSpecificTariffs?.map((e) => e.toJson()).toList(),
      };
      
  // Get tariff based on vehicle level
  double getTariffForLevel(String vehicleLevel) {
    // First, try to find in level-specific tariffs array (new API format)
    if (levelSpecificTariffs != null && levelSpecificTariffs!.isNotEmpty) {
      for (var levelTariff in levelSpecificTariffs!) {
        // Match by level name (case-insensitive partial match)
        if (levelTariff.vehicleLevelName.toLowerCase().contains(vehicleLevel.toLowerCase()) ||
            vehicleLevel.toLowerCase().contains(levelTariff.vehicleLevelName.toLowerCase())) {
          return levelTariff.tariff;
        }
      }
      // If exact match not found, try to match by level number
      // Extract level number from vehicleLevel (e.g., "Level 1" -> "1")
      final levelNum = vehicleLevel.replaceAll(RegExp(r'[^0-9]'), '');
      for (var levelTariff in levelSpecificTariffs!) {
        final tariffLevelNum = levelTariff.vehicleLevelName.replaceAll(RegExp(r'[^0-9]'), '');
        if (levelNum == tariffLevelNum && tariffLevelNum.isNotEmpty) {
          return levelTariff.tariff;
        }
      }
    }
    
    // Fallback to legacy flat fields
    if (vehicleLevel == 'Level 1' && tariffLevel1 != null) {
      return tariffLevel1!;
    } else if (vehicleLevel == 'Level 2' && tariffLevel2 != null) {
      return tariffLevel2!;
    } else if (vehicleLevel == 'Level 3' && tariffLevel3 != null) {
      return tariffLevel3!;
    }
    // Fallback to default tariff
    return tariff;
  }
}
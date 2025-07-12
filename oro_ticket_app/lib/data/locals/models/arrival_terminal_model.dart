import 'package:hive/hive.dart';

part 'arrival_terminal_model.g.dart';

@HiveType(typeId: 3)
class ArrivalTerminalModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double tariff;

  @HiveField(3) // New field added
  final double distance;

  ArrivalTerminalModel({
    required this.id,
    required this.name,
    required this.tariff,
    required this.distance, 
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

    return ArrivalTerminalModel(
      id: json['id'] ?? json['arrival_terminal_id'] ?? '',
      name: json['name'] ?? '',
      tariff: parsedTariff,
      distance: parsedDistance,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tariff': tariff.toString(),
    'distance': distance.toString(),
  };
}
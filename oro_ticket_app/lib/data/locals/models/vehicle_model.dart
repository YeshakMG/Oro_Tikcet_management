import 'package:hive/hive.dart';

part 'vehicle_model.g.dart';

@HiveType(typeId: 0)
class VehicleModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String plateNumber;

  @HiveField(2)
  final String plateRegion;

  @HiveField(3)
  final String fleetType;

  @HiveField(4)
  final String vehicleLevel;

  @HiveField(5)
  final String associationId;

  @HiveField(6)
  final int seatCapacity;

  @HiveField(7)
  final String status;

  @HiveField(8)
  final String? assignedTerminalId;

  @HiveField(9)
  final String? createdBy;

  @HiveField(10)
  final String? updatedBy;

  @HiveField(11)
  final String? createdAt;

  @HiveField(12)
  final String? updatedAt;

  @HiveField(13)
  final List<String>? arrivalTerminals;

  @HiveField(14)
  final List<String>? tariffs;

  VehicleModel({
    required this.id,
    required this.plateNumber,
    required this.plateRegion,
    required this.fleetType,
    required this.vehicleLevel,
    required this.associationId,
    required this.seatCapacity,
    required this.status,
    this.assignedTerminalId,
    required this.arrivalTerminals,
    required this.tariffs,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'],
      plateNumber: json['plate_number'],
      plateRegion: json['plate_region'] ?? '',
      fleetType: json['fleetType']['name'],
      vehicleLevel: json['vehicleLevel']['name'],
      associationId: json['association_id'],
      seatCapacity: json['seat_capacity'] ?? 0,
      status: json['status'] ?? 'active',
      assignedTerminalId: json['assigned_terminal_id'],
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      arrivalTerminals:
          (json['arrival_terminals'] as List?)?.cast<String>() ?? [],
      tariffs: (json['tariffs'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'plate_number': plateNumber,
        'plate_region': plateRegion,
        'fleetType': fleetType,
        'vehicleLevel': vehicleLevel,
        'association_id': associationId,
        'seat_capacity': seatCapacity,
        'status': status,
        'assigned_terminal_id': assignedTerminalId,
        'created_by': createdBy,
        'updated_by': updatedBy,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'arrival_terminals': arrivalTerminals ?? [],
        'tariffs': tariffs ?? [],
      };
}

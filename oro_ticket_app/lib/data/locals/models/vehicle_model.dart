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
  final String fleetTypeId;

  @HiveField(4)
  final String vehicleLevelId;

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

  VehicleModel({
    required this.id,
    required this.plateNumber,
    required this.plateRegion,
    required this.fleetTypeId,
    required this.vehicleLevelId,
    required this.associationId,
    required this.seatCapacity,
    required this.status,
    this.assignedTerminalId,
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
      fleetTypeId: json['fleet_type_id'],
      vehicleLevelId: json['vehicle_level_id'],
      associationId: json['association_id'],
      seatCapacity: json['seat_capacity'] ?? 0,
      status: json['status'] ?? 'active',
      assignedTerminalId: json['assigned_terminal_id'],
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'plate_number': plateNumber,
        'plate_region': plateRegion,
        'fleet_type_id': fleetTypeId,
        'vehicle_level_id': vehicleLevelId,
        'association_id': associationId,
        'seat_capacity': seatCapacity,
        'status': status,
        'assigned_terminal_id': assignedTerminalId,
        'created_by': createdBy,
        'updated_by': updatedBy,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}

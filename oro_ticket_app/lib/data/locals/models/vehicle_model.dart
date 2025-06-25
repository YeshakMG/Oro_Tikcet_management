import 'package:hive/hive.dart';

part 'vehicle_model.g.dart';

@HiveType(typeId: 0)
class VehicleModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String plateNumber;

  @HiveField(2)
  final String fleetTypeId;

  @HiveField(3)
  final String vehicleLevelId;

  @HiveField(4)
  final String companyId;

  @HiveField(5)
  final int seatCapacity;

  @HiveField(6)
  final String status;

  VehicleModel({
    required this.id,
    required this.plateNumber,
    required this.fleetTypeId,
    required this.vehicleLevelId,
    required this.companyId,
    required this.seatCapacity,
    required this.status,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'],
      plateNumber: json['plate_number'],
      fleetTypeId: json['fleet_type_id'],
      vehicleLevelId: json['vehicle_level_id'],
      companyId: json['company_id'],
      seatCapacity: json['seat_capacity'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'plate_number': plateNumber,
        'fleet_type_id': fleetTypeId,
        'vehicle_level_id': vehicleLevelId,
        'company_id': companyId,
        'seat_capacity': seatCapacity,
        'status': status,
      };
}

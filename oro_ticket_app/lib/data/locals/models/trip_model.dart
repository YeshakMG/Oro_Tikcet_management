import 'package:hive/hive.dart';

part 'trip_model.g.dart';

@HiveType(typeId: 4)
class TripModel extends HiveObject {
  @HiveField(0)
  String plateNumber;

  @HiveField(1)
  String plateRegion;

  @HiveField(2)
  String vehicleLevel;

  @HiveField(3)
  String associationName;

  @HiveField(4)
  int seatCapacity;

  @HiveField(5)
  String fleetTypeName;

  @HiveField(6)
  DateTime dateTime;

  @HiveField(7)
  double km;

  @HiveField(8)
  double tariff;

  @HiveField(9)
  double serviceCharge;

  @HiveField(10)
  double totalPaid;

  @HiveField(11)
  String departureTerminal;

  @HiveField(12)
  String arrivalTerminal;

  @HiveField(13)
  String employeeName;

  @HiveField(14)
  String companyName;

  TripModel({
    required this.plateNumber,
    required this.plateRegion,
    required this.vehicleLevel,
    required this.associationName,
    required this.seatCapacity,
    required this.fleetTypeName,
    required this.dateTime,
    required this.km,
    required this.tariff,
    required this.serviceCharge,
    required this.totalPaid,
    required this.departureTerminal,
    required this.arrivalTerminal,
    required this.employeeName,
    required this.companyName,
  });
}

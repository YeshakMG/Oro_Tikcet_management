import 'package:hive/hive.dart';

part 'trip_model.g.dart';

@HiveType(typeId: 5)
class TripModel extends HiveObject {
  @HiveField(0)
  String vehicleId;

  @HiveField(1)
  DateTime dateAndTime;

  @HiveField(2)
  double km;

  @HiveField(3)
  double tariff;

  @HiveField(4)
  double serviceCharge;

  @HiveField(5)
  double totalPaid;

  @HiveField(6)
  String departureTerminalId;

  @HiveField(7)
  String arrivalTerminalId;

  @HiveField(8)
  String companyId;

  @HiveField(9)
  String employeeId;

  TripModel({
    required this.vehicleId,
    required this.dateAndTime,
    required this.km,
    required this.tariff,
    required this.serviceCharge,
    required this.totalPaid,
    required this.departureTerminalId,
    required this.arrivalTerminalId,
    required this.companyId,
    required this.employeeId,
  });
}
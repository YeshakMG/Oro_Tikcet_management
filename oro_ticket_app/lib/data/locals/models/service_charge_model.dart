import 'package:hive/hive.dart';

part 'service_charge_model.g.dart';

@HiveType(typeId: 6)
class ServiceChargeModel extends HiveObject {
  @HiveField(0)
  String departureTerminal;

  @HiveField(1)
  DateTime dateTime;

  @HiveField(2)
  double serviceChargeAmount;

  @HiveField(3)
  String employeeId;

  @HiveField(4)
  String companyId;

  ServiceChargeModel({
    required this.departureTerminal,
    required this.dateTime,
    required this.serviceChargeAmount,
    required this.employeeId,
    required this.companyId,
  });

  Map<String, dynamic> toJson() => {
    "departure_terminal_id": departureTerminal,
    "date_and_time": dateTime.toIso8601String(),
    "service_charge_amount": serviceChargeAmount,
    "employee_id": employeeId,
    "company_id": companyId,
  };
}

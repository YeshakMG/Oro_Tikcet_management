import 'package:hive/hive.dart';

part 'service_charge_model.g.dart';

@HiveType(typeId: 5)
class ServiceChargeModel extends HiveObject {
  @HiveField(0)
  String departureTerminal;

  @HiveField(1)
  DateTime dateTime;

  @HiveField(2)
  double serviceChargeAmount;

  @HiveField(3)
  String employeeName;

  ServiceChargeModel({
    required this.departureTerminal,
    required this.dateTime,
    required this.serviceChargeAmount,
    required this.employeeName,
  });
}

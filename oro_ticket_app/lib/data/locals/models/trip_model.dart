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

  @HiveField(10)
  String departureName;

  @HiveField(11)
  String arrivalName;

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
    required this.departureName,
    required this.arrivalName,
  });

  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': vehicleId,
      'date_and_time': dateAndTime.toIso8601String(),
      'km': km,
      'tariff': tariff,
      'service_charge': serviceCharge,
      'total_paid': totalPaid,
      'departure_terminal_id': departureTerminalId,
      'arrival_terminal_id': arrivalTerminalId,
      'company_id': companyId,
      'employee_id': employeeId,
    };
  }

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      vehicleId: json['vehicle_id'],
      dateAndTime: DateTime.parse(json['date_and_time']),
      km: (json['km'] as num).toDouble(),
      tariff: (json['tariff'] as num).toDouble(),
      serviceCharge: (json['service_charge'] as num).toDouble(),
      totalPaid: (json['total_paid'] as num).toDouble(),
      departureTerminalId: json['departure_terminal_id'],
      arrivalTerminalId: json['arrival_terminal_id'],
      companyId: json['company_id'],
      employeeId: json['employee_id'],
      departureName: json['departure_name'] ??
          json['departureTerminal']?['name'] ??
          '', 
      arrivalName: json['arrival_name'] ??
          json['arrivalTerminal']?['name'] ??
          '',
    );
  }
}
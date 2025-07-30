import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:oro_ticket_app/app/modules/sign_in/models/user_model.dart';
import 'package:oro_ticket_app/data/locals/hive_boxes.dart';
import 'package:oro_ticket_app/data/locals/models/arrival_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/models/departure_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/models/vehicle_model.dart';
import 'package:oro_ticket_app/data/locals/models/commission_rule_model.dart';
import 'package:ethiopian_datetime/ethiopian_datetime.dart';

class TicketController extends GetxController {
  final locationFrom = ''.obs;
  final locationTo = ''.obs;
  final plateNumber = ''.obs;
  final vehicleId = ''.obs;
  final seatNo = ''.obs;
  final level = ''.obs;
  final dateTime = ''.obs;
  final km = ''.obs;
  final associationId = ''.obs;
  final regionId = ''.obs;
  final fleetType = ''.obs;
  final companyId = ''.obs;

  final tariff = ''.obs;
  final serviceCharge = ''.obs;
  final totalPayment = ''.obs;

  final commissionRate = 0.0.obs;

  // Associations
  final associations = ''.obs;
  final region = ''.obs;

  // Models
  final selectedVehicle = Rxn<VehicleModel>();
  final selectedArrival = Rxn<ArrivalTerminalModel>();

  var arrivalTerminalId = ''.obs;
  var departureTerminalId = ''.obs;

  // Afaan Oromo weekday names
  static const Map<int, String> oromoWeekdays = {
    0: 'Dilbata', // Sunday
    1: 'Wiixata', // Monday
    2: 'Qibxata', // Tuesday
    3: 'Roobii', // Wednesday
    4: 'Kamiisa', // Thursday
    5: 'Jimaata', // Friday
    6: 'Sanbata', // Saturday
  };

  // Populates ticket info and calculates charges
  void populateFromModels(
    VehicleModel vehicle,
    ArrivalTerminalModel arrival,
    DepartureTerminalModel departure,
    UserModel user,
  ) {
    selectedVehicle.value = vehicle;
    selectedArrival.value = arrival;
    vehicleId.value = vehicle.id;
    plateNumber.value = vehicle.plateNumber;
    seatNo.value = vehicle.seatCapacity.toString();
    level.value = vehicle.vehicleLevel;
    locationFrom.value = departure.id;
    locationTo.value = arrival.id;
    km.value = "${arrival.distance.toStringAsFixed(1)} km";
    tariff.value = "${arrival.tariff.toStringAsFixed(2)} ETB";
    associations.value = vehicle.associationName;
    region.value = vehicle.plateRegion;
    fleetType.value = vehicle.fleetType;
    companyId.value = user.companyId;

    final now = DateTime.now();
    final ethDate = now.convertToEthiopian();
    final weekdayOromo = oromoWeekdays[now.weekday] ?? '';
    final formattedDate =
        "${ethDate.year}/${ethDate.month.toString().padLeft(2, '0')}/${ethDate.day.toString().padLeft(2, '0')}";
    final formattedTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    dateTime.value = "$weekdayOromo - $formattedDate $formattedTime";
    calculateCharges(arrival.tariff);
  }

  // Calculate commission and total payment
  void calculateCharges(double baseTariff) async {
    final box = await HiveBoxes.getBox<CommissionRuleModel>(
        HiveBoxes.commissionRulesBox);
    final rule = box.values.firstOrNull;
    double rate = rule?.commissionRate ?? 0.0;
    commissionRate.value = rate;
    double computedService = baseTariff * rate;
    double total = baseTariff + computedService;
    serviceCharge.value = "${computedService.toStringAsFixed(2)} ETB";
    totalPayment.value = "${total.toStringAsFixed(2)} ETB";
  }
}

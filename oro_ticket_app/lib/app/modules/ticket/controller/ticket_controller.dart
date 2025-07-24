import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:ethiopian_datetime/ethiopian_datetime.dart';

import 'package:oro_ticket_app/data/locals/hive_boxes.dart';
import 'package:oro_ticket_app/data/locals/models/arrival_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/models/vehicle_model.dart';
import 'package:oro_ticket_app/data/locals/models/commission_rule_model.dart';

class TicketController extends GetxController {
  final locationFrom = ''.obs;
  final locationTo = ''.obs;
  final plateNumber = ''.obs;
  final seatNo = ''.obs;
  final level = ''.obs;
  final dateTime = ''.obs; // Combined formatted string: "Day - Date Time"
  final km = ''.obs;
  final associationId = ''.obs;
  final regionId = ''.obs;

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

  // Afaan Oromo weekday names
  static const Map<int, String> oromoWeekdays = {
    1: 'Dilbata',   // Sunday
    2: 'Wiixata',   // Monday
    3: 'Qibxata',   // Tuesday
    4: 'Roobii',    // Wednesday
    5: 'Kamiisa',   // Thursday
    6: 'Jimaata',   // Friday
    7: 'Sanbata',   // Saturday
  };

  // Populates ticket info and calculates charges
  void populateFromModels(
    VehicleModel vehicle,
    ArrivalTerminalModel arrival,
    String departureName,
    
  ) {
    selectedVehicle.value = vehicle;
    selectedArrival.value = arrival;

    plateNumber.value = vehicle.plateNumber;
    seatNo.value = vehicle.seatCapacity.toString();
    level.value = vehicle.vehicleLevel;
    locationFrom.value = departureName;
    locationTo.value = arrival.name;
    km.value = "${arrival.distance.toStringAsFixed(1)} km";
    tariff.value = "${arrival.tariff.toStringAsFixed(2)} ETB";
    associations.value = vehicle.associationName;
    region.value = vehicle.plateRegion;

    // Get current Ethiopian date
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
    final box =
        await HiveBoxes.getBox<CommissionRuleModel>(HiveBoxes.commissionRulesBox);
    final rule = box.values.firstOrNull;

    double rate = rule?.commissionRate ?? 0.0;
    commissionRate.value = rate;

    double computedService = baseTariff * rate;
    double total = baseTariff + computedService;

    serviceCharge.value = "${computedService.toStringAsFixed(2)} ETB";
    totalPayment.value = "${total.toStringAsFixed(2)} ETB";
  }
}

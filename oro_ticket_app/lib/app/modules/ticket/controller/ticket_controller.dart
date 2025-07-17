import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/data/locals/hive_boxes.dart';
import 'package:oro_ticket_app/data/locals/models/arrival_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/models/vehicle_model.dart';
import 'package:oro_ticket_app/data/locals/models/commission_rule_model.dart';
import 'package:hive/hive.dart';

class TicketController extends GetxController {
  final locationFrom = ''.obs;
  final locationTo = ''.obs;
  final plateNumber = ''.obs;
  final seatNo = ''.obs;
  final level = ''.obs;
  final dateTime = ''.obs;
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
  

  // Populates ticket info and calculates charges
  void populateFromModels(VehicleModel vehicle, ArrivalTerminalModel arrival, String departureName) {
    selectedVehicle.value = vehicle;
    selectedArrival.value = arrival;
  

    plateNumber.value = vehicle.plateNumber;
    seatNo.value = vehicle.seatCapacity.toString();
    level.value = vehicle.vehicleLevel;
    locationFrom.value = departureName;
    locationTo.value = arrival.name;
    km.value = "${arrival.distance.toStringAsFixed(1)} km";
    tariff.value = "${arrival.tariff.toStringAsFixed(2)} ETB";
    dateTime.value = DateTime.now().toString();
    associations.value = vehicle.associationName;
    region.value = vehicle.plateRegion;
    level.value = vehicle.vehicleLevel;



    calculateCharges(arrival.tariff);
  }

  void calculateCharges(double baseTariff)async {
    final box = await HiveBoxes.getBox<CommissionRuleModel>(HiveBoxes.commissionRulesBox);
    final rule = box.values.firstOrNull;

    double rate = rule?.commissionRate ?? 0.0;
    commissionRate.value = rate;

    double computedService = baseTariff * rate;
    double total = baseTariff + computedService;

    serviceCharge.value = "${computedService.toStringAsFixed(2)} ETB";
    totalPayment.value = "${total.toStringAsFixed(2)} ETB";
  }
}

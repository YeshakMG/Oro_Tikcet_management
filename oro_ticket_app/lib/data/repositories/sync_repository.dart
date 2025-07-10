import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:oro_ticket_app/app/modules/sign_in/services/auth_service.dart';
import 'package:oro_ticket_app/data/locals/models/arrival_model.dart';
import 'package:oro_ticket_app/data/locals/models/departure_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/service/arrival_storage_service.dart';
import 'package:oro_ticket_app/data/locals/service/departure_terminal_storage_service.dart';
import '../locals/models/vehicle_model.dart';
import '../locals/hive_boxes.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SyncRepository {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  final storage = FlutterSecureStorage();

  Future<void> syncVehicles(List<Map<String, dynamic>> jsonVehicles) async {
    final box = Hive.box<VehicleModel>(HiveBoxes.vehiclesBox);
    await box.clear();
    final vehicles = jsonVehicles.map((e) => VehicleModel.fromJson(e)).toList();
    await box.addAll(vehicles);
  }

  // Future<void> syncCompanyUserVehicles() async {
  //   final authService = Get.find<AuthService>();
  //   final token = await authService.getToken();

  //   final response = await http.get(
  //     Uri.parse('$baseUrl/vehicles/company-user/my-vehicles'),
  //     headers: {
  //       'Authorization': 'Bearer $token',
  //       'Accept': 'application/json',
  //     },
  //   );

  //   if (response.statusCode == 200) {
  //     final Map<String, dynamic> json = jsonDecode(response.body);
  //     final vehicles = json['data']['vehicles'] as List<dynamic>;

  //     final box = Hive.box<VehicleModel>(HiveBoxes.vehiclesBox);
  //     await box.clear();
  //     await box.addAll(
  //       vehicles.map((v) => VehicleModel.fromJson(v)).toList(),
  //     );
  //   } else {
  //     throw Exception('Failed to sync vehicles: ${response.body}');
  //   }
  // }
  Future<void> syncCompanyUserVehicles() async {
    final authService = Get.find<AuthService>();
    final token = await authService.getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/vehicles/company-user/my-vehicles'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final vehicles = json['data']['vehicles'] as List<dynamic>;

      // Sync vehicles
      final vehicleBox = Hive.box<VehicleModel>(HiveBoxes.vehiclesBox);
      await vehicleBox.clear();
      await vehicleBox.addAll(
        vehicles.map((v) => VehicleModel.fromJson(v)).toList(),
      );

      // Sync arrival terminals
      final arrivalBox = Hive.box<ArrivalModel>(HiveBoxes.arrivalTerminalsBox);
      await arrivalBox.clear();

      final arrivals = <ArrivalModel>[];

      for (var vehicle in vehicles) {
        final destinations = vehicle['vehicleTerminalDestinations'] ?? [];

        for (var dest in destinations) {
          final terminal = dest['terminalDestination']?['arrivalTerminal'];
          if (terminal != null) {
            final arrival = ArrivalModel(
              id: terminal['id'],
              name: terminal['name'],
            );
            arrivals.add(arrival);
          }
        }
      }

      // Use ID as key to avoid duplicates
      for (var arrival in arrivals) {
        await arrivalBox.put(arrival.id, arrival);
      }

      print('✅ Synced ${arrivals.length} arrival terminals.');
    } else {
      throw Exception('Failed to sync vehicles: ${response.body}');
    }
  }

  List<VehicleModel> getLocalVehicles() {
    final box = Hive.box<VehicleModel>(HiveBoxes.vehiclesBox);
    return box.values.toList();
  }

  Future<void> syncDepartureTerminal(Map<String, dynamic> terminalJson) async {
    final terminal = DepartureTerminalModel.fromJson(terminalJson);
    await DepartureTerminalStorageService.saveTerminal(terminal);
  }

  DepartureTerminalModel? getLocalDepartureTerminal() {
    return DepartureTerminalStorageService.getTerminal();
  }
}

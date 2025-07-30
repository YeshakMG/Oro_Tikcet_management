import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:oro_ticket_app/app/modules/sign_in/services/auth_service.dart';
import 'package:oro_ticket_app/data/locals/models/arrival_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/models/commission_rule_model.dart';
import 'package:oro_ticket_app/data/locals/models/departure_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/models/trip_model.dart';
import 'package:oro_ticket_app/data/locals/service/arrival_storage_service.dart';
import 'package:oro_ticket_app/data/locals/service/commission_rule_storage_service.dart';
import 'package:oro_ticket_app/data/locals/service/departure_terminal_storage_service.dart';
import 'package:oro_ticket_app/data/locals/service/trip_storage_service.dart';
import '../locals/models/vehicle_model.dart';
import '../locals/hive_boxes.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SyncRepository {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  final storage = FlutterSecureStorage();

// For Vehicles
  Future<void> syncVehicles(List<Map<String, dynamic>> jsonVehicles) async {
    final box = Hive.box<VehicleModel>(HiveBoxes.vehiclesBox);
    await box.clear();
    final vehicles = jsonVehicles.map((e) => VehicleModel.fromJson(e)).toList();
    await box.addAll(vehicles);
  }

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

      final box = Hive.box<VehicleModel>(HiveBoxes.vehiclesBox);
      await box.clear();
      await box.addAll(
        vehicles.map((v) => VehicleModel.fromJson(v)).toList(),
      );
    } else {
      throw Exception('Failed to sync vehicles: ${response.body}');
    }
  }

  List<VehicleModel> getLocalVehicles() {
    final box = Hive.box<VehicleModel>(HiveBoxes.vehiclesBox);
    return box.values.toList();
  }

  List<ArrivalTerminalModel> getLocalArrivalTerminals() {
    return ArrivalTerminalStorageService.getTerminals();
  }

// For Departure
  Future<void> syncDepartureTerminal(Map<String, dynamic> terminalJson) async {
    final terminal = DepartureTerminalModel.fromJson(terminalJson);
    await DepartureTerminalStorageService.saveTerminal(terminal);
  }

  DepartureTerminalModel? getLocalDepartureTerminal() {
    return DepartureTerminalStorageService.getTerminal();
  }

// For Arrivals
  Future<void> syncArrivalTerminals(
      List<Map<String, dynamic>> jsonTerminals) async {
    final terminals =
        jsonTerminals.map((e) => ArrivalTerminalModel.fromJson(e)).toList();
    await ArrivalTerminalStorageService.saveTerminals(terminals);
  }

  Future<void> syncCompanyUserArrivalTerminals() async {
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

      final arrivalTerminals = <ArrivalTerminalModel>[];

      for (final vehicle in vehicles) {
        final destinations =
            vehicle['vehicleTerminalDestinations'] as List<dynamic>?;

        if (destinations != null) {
          for (final dest in destinations) {
            final terminalDestination = dest['terminalDestination'];

            if (terminalDestination != null) {
              print('Full terminalDestination JSON: $terminalDestination');
              final arrivalTerminal =
                  terminalDestination['arrivalTerminal'] ?? {};

              // Debug print raw arrivalTerminal JSON to inspect actual content
              print('Raw arrivalTerminal JSON: $arrivalTerminal');

              // Try to extract id and name directly or check nested keys if needed
              // Example if nested deeper, you can add logic here after seeing the debug output

              final terminalId = arrivalTerminal['id'] ??
                  arrivalTerminal['arrival_terminal_id'] ??
                  '';

              final terminalName = arrivalTerminal['name'] ??
                  arrivalTerminal['terminal_name'] ??
                  '';

              print("Parsed terminal: id=$terminalId, name=$terminalName");

              // Handle tariff conversion
              dynamic tariffValue = vehicle['tariff']?['tariff'] ?? 0.0;
              double parsedTariff = 0.0;

              if (tariffValue is String) {
                parsedTariff = double.tryParse(tariffValue) ?? 0.0;
              } else if (tariffValue is int) {
                parsedTariff = tariffValue.toDouble();
              } else if (tariffValue is double) {
                parsedTariff = tariffValue;
              }

              // Handle distance conversion
              dynamic distanceValue = terminalDestination['distance'] ?? 0.0;
              double parsedDistance = 0.0;

              if (distanceValue is String) {
                parsedDistance = double.tryParse(distanceValue) ?? 0.0;
              } else if (distanceValue is int) {
                parsedDistance = distanceValue.toDouble();
              } else if (distanceValue is double) {
                parsedDistance = distanceValue;
              }

              arrivalTerminals.add(
                ArrivalTerminalModel.fromJson({
                  'id': terminalId,
                  'name': terminalName,
                  'tariff': parsedTariff,
                  'distance': parsedDistance,
                }),
              );
            }
          }
        }
      }

      // Save to Hive after transformation
      await syncArrivalTerminals(
        arrivalTerminals.map((e) => e.toJson()).toList(),
      );
    } else {
      throw Exception('Failed to sync arrival terminals: ${response.body}');
    }
  }

// For Commission
  Future<void> syncCommissionRules() async {
    final authService = Get.find<AuthService>();
    final token = await authService.getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/commission-rules'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = json['data'] as List<dynamic>;

      final rules = data
          .map((ruleJson) => CommissionRuleModel.fromJson(ruleJson))
          .toList();

      await CommissionRuleStorageService.saveCommissionRules(rules);

      print('Commission rules fetched: ${rules.length}');
      for (var rule in rules) {
        print(
            'Rule ${rule.id}: companyId=${rule.companyId}, rate=${rule.commissionRate}');
      }

      final stored = CommissionRuleStorageService.getCommissionRules();
      print('Commission rules stored locally: ${stored.length}');
    } else {
      print('Failed to fetch commission rules: ${response.body}');
      throw Exception('Failed to sync commission rules');
    }
  }

  Future<void> syncTripsToServer() async {
    try {
      final authService = Get.find<AuthService>();
      final token = await authService.getToken();
      final tripStorageService = TripStorageService();
      final trips = tripStorageService.getAllTrips();

      if (trips.isEmpty) {
        print('No trips to sync');
        Get.snackbar("", "No trips to sync");
        return;
      }

      // Send each trip individually instead of nested array
      for (final trip in trips) {
        try {
          final response = await http.post(
            Uri.parse('$baseUrl/trips'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(trip.toJson()),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            print('Trip synced successfully: ${trip.vehicleId}');
            await tripStorageService.clearTrips();
            print('All trips processed');
          } else {
            print('Failed to sync trip: ${response.body}');
            print('Sent payload: ${jsonEncode(trip.toJson())}');
          }
        } catch (e) {
          print('Error syncing individual trip: $e');
          continue; // Continue with next trip if one fails
        }
      }

 
    } catch (e) {
      print('Error in sync process: $e');
      throw Exception('Error syncing trips: $e');
    }
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
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
import 'package:oro_ticket_app/data/locals/service/user_storage_service.dart';

import 'package:oro_ticket_app/data/locals/models/service_charge_model.dart';

import '../locals/models/vehicle_model.dart';
import '../locals/hive_boxes.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SyncRepository {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://196.189.247.242:4501/api';

  final storage = FlutterSecureStorage();
  final Connectivity _connectivity = Connectivity();
  final _vehicleChanges = StreamController<void>.broadcast();
  Stream<void> get vehicleChanges => _vehicleChanges.stream;

  // Helper method to check network connectivity
  Future<bool> get _isOnline async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<bool> get isOnline async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      print('⚠️ Connectivity check error: $e');
      return false;
    }
  }

  // ========== VEHICLES ========== //
  Future<List<VehicleModel>> getVehicles() async {
    try {
      // Always return local storage immediately
      final localVehicles = getLocalVehicles();
      if (localVehicles.isNotEmpty) {
        print('📦 Returning vehicles from local storage');
        for (var vehicle in localVehicles) {
          print('number of vehicle stored in local: ${localVehicles.length}');
          print('${vehicle.toJson()}');
        }
        return localVehicles;
      }

      // Only attempt API if online
      if (await _isOnline) {
        print('🌐 Attempting to fetch vehicles from API');
        await syncAllCompanyUserVehicles();
        return getLocalVehicles();
      }

      return localVehicles;
    } catch (e) {
      print('⚠️ Error in getVehicles(), falling back to local: $e');
      return getLocalVehicles(); // Always fall back to local
    }
  }

  Future<void> syncAllCompanyUserVehicles({bool forceSync = false}) async {
    if (!await _isOnline && !forceSync) {
      print('🚫 Offline - Skipping vehicle sync');
      return;
    }

    try {
      final authService = Get.find<AuthService>();
      final token = await authService.getToken();
      final box = Hive.box<VehicleModel>(HiveBoxes.vehiclesBox);

      // Get the assigned terminal from local storage
      final terminal = DepartureTerminalStorageService.getTerminal();
      final terminalId = terminal?.id;
      
      if (terminalId == null) {
        print('⚠️ No terminal assigned to user, cannot fetch vehicles');
        return;
      }

      int currentPage = 1;
      bool hasMorePages = true;
      int totalSynced = 0;
      final Set<String> apiVehicleIds = {};

      while (hasMorePages) {
        print('🔄 Fetching vehicles page $currentPage...');
        final response = await http.get(
          Uri.parse(
              '$baseUrl/vehicles/company-user/my-vehicles?terminal_id=$terminalId&page=$currentPage'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          print('📥 API Response keys: ${json.keys}'); // Debug: see response structure
          
          // Try different possible pagination paths
          Map<String, dynamic>? pagination;
          var vehicles = <dynamic>[];
          
          // Check if data.vehicles exists directly
          if (json['data'] is Map) {
            final data = json['data'] as Map<String, dynamic>;
            vehicles = data['vehicles'] as List<dynamic>? ?? [];
            pagination = data['pagination'] as Map<String, dynamic>?;
            
            // Also try 'meta' for pagination (common Laravel format)
            if (pagination == null) {
              pagination = data['meta'] as Map<String, dynamic>?;
            }
          }
          
          print('📦 Found ${vehicles.length} vehicles on page $currentPage');
          print('📄 Pagination data: $pagination');
          
          final validVehicles = vehicles
              .where((e) => e['deleted_at'] == null)
              .map((e) => VehicleModel.fromJson(e))
              .toList();

          for (final vehicle in validVehicles) {
            apiVehicleIds.add(vehicle.id);
          }

          await box.putAll(
              {for (final vehicle in validVehicles) vehicle.id: vehicle});

          totalSynced += validVehicles.length;
          print(
              '✅ Synced ${validVehicles.length} vehicles from page $currentPage (total: $totalSynced)');

          // Handle pagination safely - check multiple possible structures
          if (pagination != null && pagination.isNotEmpty) {
            // Try different pagination field names
            final currentPageVal = pagination['current_page'] ?? 
                                   pagination['page'] ?? 
                                   pagination['currentPage'] ?? 
                                   1;
            final lastPageVal = pagination['last_page'] ?? 
                                pagination['total_pages'] ?? 
                                pagination['lastPage'] ?? 
                                pagination['total'] != null 
                                  ? ((pagination['total'] as int) / (pagination['per_page'] ?? pagination['perPage'] ?? 15)).ceil()
                                  : 1;
            
            print('📊 Pagination: current=$currentPageVal, last=$lastPageVal');
            hasMorePages = currentPageVal < lastPageVal;
          } else {
            // No pagination info - check if there's more data by seeing if we got a full page
            // If we got 10 vehicles (common page size), assume there might be more pages
            // Continue fetching until we get fewer vehicles than the page size
            hasMorePages = validVehicles.length >= 10; // Common page size is 10
            print('📊 No pagination info, checking if more pages: hasMore=$hasMorePages (got ${validVehicles.length} vehicles)');
          }
          currentPage++;
        } else {
          print('⚠️ API returned ${response.statusCode}, stopping sync');
          break;
        }
      }

      if (totalSynced > 0) {
        final localIds = box.keys.cast<String>().toSet();
        final idsToRemove = localIds.difference(apiVehicleIds);
        await box.deleteAll(idsToRemove);
        _vehicleChanges.add(null);
        print('✅ Synced $totalSynced vehicles across ${currentPage - 1} pages');
      }
    } catch (e) {
      print('⚠️ Sync error (continuing with local data): $e');
      rethrow; // Let the caller handle the error
    }
  }

  List<VehicleModel> getLocalVehicles() {
    try {
      final box = Hive.box<VehicleModel>(HiveBoxes.vehiclesBox);
      return box.values.toList();
    } catch (e) {
      print('❌ Error getting local vehicles: $e');
      return [];
    }
  }

  Future<void> clearLocalVehicles() async {
    try {
      final box = Hive.box<VehicleModel>(HiveBoxes.vehiclesBox);
      await box.clear();
      print('🗑️ Local vehicles cleared');
    } catch (e) {
      print('❌ Error clearing local vehicles: $e');
    }
  }

  Future<void> syncVehicles(List<Map<String, dynamic>> jsonVehicles) async {
    // Delete the old box data
    await Hive.deleteBoxFromDisk(HiveBoxes.vehiclesBox);

    // Reopen the box
    final box = await Hive.openBox<VehicleModel>(HiveBoxes.vehiclesBox);

    // Filter out deleted vehicles and convert to model
    final vehicles = jsonVehicles
        .where((e) => e['deleted_at'] == null)
        .map((e) => VehicleModel.fromJson(e))
        .toList();

    // Sync only non-deleted vehicles
    await box.addAll(vehicles);
  }
  /*Future<void> syncCompanyUserVehicles() async {
    final authService = Get.find<AuthService>();
    final token = await authService.getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/vehicles/company-user/terminals/my-vehicles'),
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
*/

  // List<VehicleModel> getLocalVehicles() {
  //   final box = Hive.box<VehicleModel>(HiveBoxes.vehiclesBox);
  //   return box.values.toList();
  // }

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
    final seenNames = <String>{};
    final uniqueTerminals = jsonTerminals
        .where((e) {
          final name = e['name']?.toString().trim().toLowerCase();
          if (name == null || seenNames.contains(name)) {
            return false;
          } else {
            seenNames.add(name);
            return true;
          }
        })
        .map((e) => ArrivalTerminalModel.fromJson(e))
        .toList();

    await ArrivalTerminalStorageService.saveTerminals(uniqueTerminals);
  }

  Future<void> syncCompanyUserArrivalTerminals() async {
    final authService = Get.find<AuthService>();
    final token = await authService.getToken();

    // New API endpoint for terminals with destinations
    final response = await http.get(
      Uri.parse('$baseUrl/terminals/company-user/arrival-terminals'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      print('📡 Arrival Terminals API Response: $json');
      
      // Handle the new response format - extract arrival_terminals from data
      final Map<String, dynamic>? data = json['data'] as Map<String, dynamic>?;
      final List<dynamic> terminals = data?['arrival_terminals'] is List ? data!['arrival_terminals'] : [];
      
      final arrivalTerminals = <ArrivalTerminalModel>[];
      final seenTerminalIds = <String>{};

      for (final terminal in terminals) {
        final terminalId = terminal['terminal_id']?.toString() ?? '';
        final terminalName = terminal['terminal_name']?.toString() ?? '';
        
        // Avoid duplicates
        if (terminalId.isNotEmpty && !seenTerminalIds.contains(terminalId)) {
          seenTerminalIds.add(terminalId);
          
          // Handle tariff conversion
          dynamic tariffValue = terminal['tariff'] ?? 0.0;
          double parsedTariff = 0.0;
          
          if (tariffValue is String) {
            parsedTariff = double.tryParse(tariffValue) ?? 0.0;
          } else if (tariffValue is int) {
            parsedTariff = tariffValue.toDouble();
          } else if (tariffValue is double) {
            parsedTariff = tariffValue;
          }
          
          // Handle distance conversion
          dynamic distanceValue = terminal['distance'] ?? 0.0;
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
          
          print("Parsed terminal from new API: id=$terminalId, name=$terminalName, distance=$parsedDistance, tariff=$parsedTariff");
        }
      }

      // Save to Hive after transformation
      await syncArrivalTerminals(
        arrivalTerminals.map((e) => e.toJson()).toList(),
      );
      
      print('Total arrival terminals saved: ${arrivalTerminals.length}');
    } else {
      throw Exception('Failed to sync arrival terminals: ${response.statusCode} - ${response.body}');
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

      // ✅ Filter out deleted rules (adjust key name as per your API)
      final activeRules = data
          .where((ruleJson) =>
              ruleJson['deleted'] == null || ruleJson['deleted'] == false)
          .map((ruleJson) => CommissionRuleModel.fromJson(ruleJson))
          .toList();

      await CommissionRuleStorageService.saveCommissionRules(activeRules);

      print('Commission rules fetched: ${activeRules.length}');
      for (var rule in activeRules) {
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

  Future<int> syncTripsToServer() async {
    try {
      final authService = Get.find<AuthService>();
      final token = await authService.getToken();
      final tripStorageService = TripStorageService();
      final trips = tripStorageService.getAllTrips();

      if (trips.isEmpty) {
        print('No trips to sync');
        if (Get.context != null) {
          Get.snackbar("Info", "No trips to sync",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange,
              colorText: Colors.white);
        }
        return 0;
      }

      int syncedCount = 0;
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
            trip.isSynced = true;
            print('Trip synced successfully: ${trip.vehicleId}');
            await tripStorageService.clearTrips();
            print('All trips processed');
            print('Sent payload: ${jsonEncode(trip.toJson())}');
            syncedCount++;
          } else {
            print('Failed to sync trip: ${response.body}');
            print('Sent payload: ${jsonEncode(trip.toJson())}');
          }
        } catch (e) {
          print('Error syncing individual trip: $e');
          continue; // Continue with next trip if one fails
        }
      }

      // Show success message after all trips are synced
      if (syncedCount > 0 && Get.context != null) {
        Get.snackbar("Success", "$syncedCount trip(s) synced successfully",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white);
      } else if (Get.context != null) {
        Get.snackbar("Warning", "No trips were synced",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white);
      }

      return syncedCount;
    } catch (e) {
      print('Error in sync process: $e');
      if (Get.context != null) {
        Get.snackbar("Error", "Failed to sync trips: $e",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
      }
      throw Exception('Error syncing trips: $e');
    }
  }

Future<int> syncServiceChargeToServer() async {
  final authService = Get.find<AuthService>();
  final token = await authService.getToken();
  final box = Hive.box<ServiceChargeModel>(HiveBoxes.serviceChargeBox);

  if (box.isEmpty) {
    if (Get.context != null) {
      Get.snackbar("Info", "No service charges to sync",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white);
    }
    return 0;
  }

  final entries = box.toMap();
  int syncedCount = 0;
  int failedCount = 0;

  for (final entry in entries.entries) {
    final key = entry.key;
    final serviceCharge = entry.value;

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/service-charges"), // 👈 replace with real URL
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(serviceCharge.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Synced: ${serviceCharge.departureTerminal}');
        await box.delete(key);
        syncedCount++;
      } else {
        print('❌ Failed (${response.statusCode}): ${response.body}');
        failedCount++;
      }
    } catch (e) {
      print('❗ Sync error: $e');
      failedCount++;
    }
  }

  // Show single success message after all are processed
  if (Get.context != null) {
    if (syncedCount > 0 && failedCount == 0) {
      Get.snackbar("Success", "$syncedCount service charge(s) synced successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } else if (syncedCount > 0 && failedCount > 0) {
      Get.snackbar("Warning", "$syncedCount synced, $failedCount failed",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white);
    } else if (failedCount > 0) {
      Get.snackbar("Error", "$failedCount service charge(s) failed to sync",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  return syncedCount;
}

}

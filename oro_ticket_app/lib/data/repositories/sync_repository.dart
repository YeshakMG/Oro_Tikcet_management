import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';
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

  List<VehicleModel> getLocalVehicles() {
    final box = Hive.box<VehicleModel>(HiveBoxes.vehiclesBox);
    return box.values.toList();
  }

  Future<void> syncVehiclesFromApi(String companyId) async {
    try {
      final token = await storage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse('$baseUrl/vehicles?company_id=$companyId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data = json['data'];
        await syncVehicles(List<Map<String, dynamic>>.from(data));
      } else {
        throw Exception('Failed to fetch vehicles: ${response.body}');
      }
    } catch (e) {
      print('Vehicle Sync Error: $e');
    }
  }
}

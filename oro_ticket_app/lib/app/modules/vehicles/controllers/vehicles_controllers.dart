import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:oro_ticket_app/app/modules/sign_in/services/auth_service.dart';
import 'package:oro_ticket_app/data/locals/models/vehicle_model.dart';
import 'package:oro_ticket_app/data/repositories/sync_repository.dart';

class VehiclesController extends GetxController {
  final SyncRepository syncRepo = SyncRepository();

  RxList<VehicleModel> allVehicles = <VehicleModel>[].obs;
  RxList<VehicleModel> filteredVehicles = <VehicleModel>[].obs;
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  @override
  void onInit() {
    super.onInit();
    fetchAndSyncVehicles();
  }

  Future<void> fetchAndSyncVehicles() async {
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
      final data = jsonDecode(response.body);
      final vehicles =
          List<Map<String, dynamic>>.from(data['data']['vehicles']);
      await syncRepo.syncVehicles(vehicles);
      loadVehicles();
      List<VehicleModel> localVehicles = syncRepo.getLocalVehicles();
      print('Number of vehicles stored: ${localVehicles.length}');
      for (var vehicle in localVehicles) {
        print(vehicle.toJson());
      }
    } else {
      print('Failed to fetch vehicles: ${response.body}');
    }
  }

  void loadVehicles() {
    final vehicles = syncRepo.getLocalVehicles();
    allVehicles.assignAll(vehicles);
    filteredVehicles.assignAll(vehicles);
  }

  void filterVehicles(String query) {
    if (query.isEmpty) {
      filteredVehicles.assignAll(allVehicles);
    } else {
      filteredVehicles.assignAll(
        allVehicles.where((v) =>
            v.plateNumber.toLowerCase().contains(query.toLowerCase()) ||
            v.status.toLowerCase().contains(query.toLowerCase())),
      );
    }
  }
}

// import 'package:get/get.dart';

// class VehiclesController extends GetxController {
//   RxList<Map<String, String>> vehicles = <Map<String, String>>[].obs;

//   @override
//   void onInit() {
//     super.onInit();
//     loadVehicles();
//   }

//   void loadVehicles() {
//     vehicles.assignAll([
//       {'level': '2', 'seat': '14 Adama', 'terminal': 'Afar'},
//       {'level': '1', 'seat': '29 Adama', 'terminal': 'Peacock Ter'},
//       {'level': '1', 'seat': '29 Adama', 'terminal': 'Peacock Ter'},
//       {'level': '2', 'seat': '29 Adama', 'terminal': 'Peacock Ter'},
//       {'level': '3', 'seat': '44 Adama', 'terminal': 'Peacock Ter'},
//       {'level': '3', 'seat': '14 Adama', 'terminal': 'Peacock Ter'},
//       {'level': '1', 'seat': '29 Adama', 'terminal': 'Peacock Ter'},
//       {'level': '2', 'seat': '14 Adama', 'terminal': 'Peacock Ter'},
//       {'level': '1', 'seat': '29 Adama', 'terminal': 'Peacock Ter'},
//       {'level': '1', 'seat': '29 Adama', 'terminal': 'Peacock Ter'},
//     ]);
//   }

//   void filterVehicles(String query) {
//     if (query.isEmpty) {
//       loadVehicles();
//     } else {
//       vehicles.assignAll(vehicles.where((vehicle) =>
//           vehicle['seat']!.toLowerCase().contains(query.toLowerCase()) ||
//           vehicle['terminal']!.toLowerCase().contains(query.toLowerCase())));
//     }
//   }

//   void addVehicle(String id, String name) {
//     vehicles.add({'id': id, 'name': name});
//   }

//   void removeVehicle(String id) {
//     vehicles.removeWhere((vehicle) => vehicle['id'] == id);
//   }
// }

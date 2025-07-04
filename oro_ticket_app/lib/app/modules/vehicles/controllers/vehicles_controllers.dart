import 'package:get/get.dart';

class VehiclesController extends GetxController {
  RxList<Map<String, String>> vehicles = <Map<String, String>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadVehicles();
  }

  void loadVehicles() {
    vehicles.assignAll([
      {'level': '2', 'seat': '14 Adama', 'terminal': 'Afar'},
      {'level': '1', 'seat': '29 Adama', 'terminal': 'Peacock Ter'},
      {'level': '1', 'seat': '29 Adama', 'terminal': 'Peacock Ter'},
      {'level': '2', 'seat': '29 Adama', 'terminal': 'Peacock Ter'},
      {'level': '3', 'seat': '44 Adama', 'terminal': 'Peacock Ter'},
      {'level': '3', 'seat': '14 Adama', 'terminal': 'Peacock Ter'},
      {'level': '1', 'seat': '29 Adama', 'terminal': 'Peacock Ter'},
      {'level': '2', 'seat': '14 Adama', 'terminal': 'Peacock Ter'},
      {'level': '1', 'seat': '29 Adama', 'terminal': 'Peacock Ter'},
      {'level': '1', 'seat': '29 Adama', 'terminal': 'Peacock Ter'},
    ]);
  }

  void filterVehicles(String query) {
    if (query.isEmpty) {
      loadVehicles();
    } else {
      vehicles.assignAll(vehicles.where((vehicle) =>
          vehicle['seat']!.toLowerCase().contains(query.toLowerCase()) ||
          vehicle['terminal']!.toLowerCase().contains(query.toLowerCase())));
    }
  }

  void addVehicle(String id, String name) {
    vehicles.add({'id': id, 'name': name});
  }

  void removeVehicle(String id) {
    vehicles.removeWhere((vehicle) => vehicle['id'] == id);
  }
}

// import 'package:get/get.dart';
// import 'package:oro_ticket_app/data/locals/models/vehicle_model.dart';
// import 'package:oro_ticket_app/data/repositories/sync_repository.dart';

// class VehiclesController extends GetxController {
//   final SyncRepository syncRepo = SyncRepository();

//   RxList<VehicleModel> allVehicles = <VehicleModel>[].obs;
//   RxList<VehicleModel> filteredVehicles = <VehicleModel>[].obs;

//   @override
//   void onInit() {
//     super.onInit();
//     loadVehicles();
//   }

//   void loadVehicles() {
//     final vehicles = syncRepo.getLocalVehicles();
//     allVehicles.assignAll(vehicles);
//     filteredVehicles.assignAll(vehicles);
//   }

//   void filterVehicles(String query) {
//     if (query.isEmpty) {
//       filteredVehicles.assignAll(allVehicles);
//     } else {
//       final result = allVehicles
//           .where((v) =>
//               v.plateNumber.toLowerCase().contains(query.toLowerCase()) ||
//               v.status.toLowerCase().contains(query.toLowerCase()))
//           .toList();
//       filteredVehicles.assignAll(result);
//     }
//   }

//   Future<void> syncVehiclesFromApi(
//       List<Map<String, dynamic>> jsonVehicles) async {
//     await syncRepo.syncVehicles(jsonVehicles);
//     loadVehicles();
//   }
// }

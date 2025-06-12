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

  void filterVehicles(String query){
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
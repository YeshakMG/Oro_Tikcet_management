import 'package:get/get.dart';
import 'package:oro_ticket_app/data/locals/models/vehicle_model.dart';
import 'package:oro_ticket_app/data/repositories/sync_repository.dart';

class VehiclesController extends GetxController {
  final SyncRepository syncRepo = SyncRepository();

  RxList<VehicleModel> allVehicles = <VehicleModel>[].obs;
  RxList<VehicleModel> filteredVehicles = <VehicleModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadVehicles();
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
      final result = allVehicles
          .where((v) =>
              v.plateNumber.toLowerCase().contains(query.toLowerCase()) ||
              v.status.toLowerCase().contains(query.toLowerCase()))
          .toList();
      filteredVehicles.assignAll(result);
    }
  }

  Future<void> syncVehiclesFromApi(
      List<Map<String, dynamic>> jsonVehicles) async {
    await syncRepo.syncVehicles(jsonVehicles);
    loadVehicles();
  }
}

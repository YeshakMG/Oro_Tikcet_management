import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:oro_ticket_app/data/locals/models/arrival_model.dart';
import 'package:oro_ticket_app/data/locals/service/arrival_storage_service.dart';
import 'package:oro_ticket_app/data/repositories/sync_repository.dart';

import '../../../../data/locals/hive_boxes.dart';

class ArrivalLocationController extends GetxController {
  var Locations = <ArrivalModel>[].obs;
  var allLocations = <ArrivalModel>[].obs;

  @override
  void onInit() async {
    super.onInit();
    final syncRepo = SyncRepository();
    await syncRepo.syncCompanyUserVehicles();
    await loadLocations();
  }

  Future<void> loadLocations() async {
    final service = ArrivalStorageService();
    // final list = await service();

    // Debug outputt
    final box = Hive.box<ArrivalModel>(HiveBoxes.arrivalTerminalsBox);
    print('Hive Box Arrival Items Count: ${box.length}');
    for (var item in box.values) {
      print('Arrival: ${item.id} - ${item.name}');
    }

    // allLocations.value = list;
    // Locations.value = list;
  }

  void filterLocations(String query) {
    if (query.isEmpty) {
      Locations.value = allLocations;
    } else {
      Locations.value = allLocations.where((item) {
        return item.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
  }
}

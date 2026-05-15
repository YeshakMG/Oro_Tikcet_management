import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/data/locals/models/departure_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/service/departure_terminal_storage_service.dart';
import 'package:oro_ticket_app/data/repositories/sync_repository.dart';

class DepartureControllers extends GetxController {
  late final SyncRepository syncRepo;
  Rx<DepartureTerminalModel?> terminal = Rx<DepartureTerminalModel?>(null);

  @override
  void onInit() {
    super.onInit();
    // Try to get existing SyncRepository or create new one
    if (Get.isRegistered<SyncRepository>()) {
      syncRepo = Get.find<SyncRepository>();
    } else {
      syncRepo = Get.put(SyncRepository());
    }
    loadTerminal();
  }

  void loadTerminal() {
    // terminal.value = DepartureTerminalStorageService.getTerminal();
    terminal.value = syncRepo.getLocalDepartureTerminal();
    if (kDebugMode) {
      print('--- Current Stored Departure Terminal ---');
      if (terminal.value == null) {
        print('No terminal stored');
      } else {
        print(terminal.value!.toJson());
      }
    }
  }

  Future<void> refreshTerminal() async {
    // Just reload from local storage (don't clear)
    loadTerminal();
  }

  Future<void> syncTerminalFromApi(Map<String, dynamic> json) async {
    // Save terminal (this will clear old data and save new)
    await syncRepo.syncDepartureTerminal(json);
    loadTerminal();
  }
}

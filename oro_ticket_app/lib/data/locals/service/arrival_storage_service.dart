// lib/data/locals/service/arrival_terminal_storage_service.dart
import 'package:hive/hive.dart';
import 'package:oro_ticket_app/data/locals/models/arrival_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/hive_boxes.dart';

class ArrivalTerminalStorageService {
  static Future<void> saveTerminals(
      List<ArrivalTerminalModel> terminals) async {
    final box = await HiveBoxes.getBox<ArrivalTerminalModel>(HiveBoxes.arrivalTerminalsBox);
    await box.clear();
    await box.addAll(terminals);
    print('✅ Saved ${terminals.length} arrival terminals to local storage');
  }

  static List<ArrivalTerminalModel> getTerminals() {
    final box = Hive.box<ArrivalTerminalModel>(HiveBoxes.arrivalTerminalsBox);
    final terminals = box.values.toList();
    print('📦 Retrieved ${terminals.length} arrival terminals from local storage');
    return terminals;
  }

  static Future<void> clearTerminals() async {
    final box = await HiveBoxes.getBox<ArrivalTerminalModel>(HiveBoxes.arrivalTerminalsBox);
    await box.clear();
  }
}

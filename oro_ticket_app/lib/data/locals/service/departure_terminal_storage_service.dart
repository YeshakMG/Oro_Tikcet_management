import 'package:hive/hive.dart';
import '../models/departure_terminal_model.dart';
import '../hive_boxes.dart';

class DepartureTerminalStorageService {
  static Future<void> saveTerminal(DepartureTerminalModel terminal) async {
    final box = await HiveBoxes.getBox<DepartureTerminalModel>(HiveBoxes.departureTerminalsBox);
    await box.clear();
    await box.put(terminal.id, terminal);
    print('✅ Departure terminal saved: ${terminal.name}');
  }

  static DepartureTerminalModel? getTerminal() {
    final box = Hive.box<DepartureTerminalModel>(HiveBoxes.departureTerminalsBox);
    if (box.values.isNotEmpty) {
      print('📦 Retrieved departure terminal from local: ${box.values.first.name}');
      return box.values.first;
    }
    return null;
  }

  static Future<void> clearAll() async {
    final box = await HiveBoxes.getBox<DepartureTerminalModel>(HiveBoxes.departureTerminalsBox);
    await box.clear();
  }
  
}


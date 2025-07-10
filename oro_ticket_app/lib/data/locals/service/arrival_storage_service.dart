import 'package:hive/hive.dart';
import 'package:oro_ticket_app/data/locals/hive_boxes.dart';
import '../models/arrival_model.dart';

class ArrivalStorageService {
  static const String boxName = 'arrival_locations';
  
  static Future<void> saveArrival(ArrivalModel model) async {
    final box = Hive.box<ArrivalModel>(HiveBoxes.arrivalTerminalsBox);
    await box.put(model.id, model);
  }

  static Future<List<ArrivalModel>> getArrivalTerminals() async {
    final box = Hive.box<ArrivalModel>(HiveBoxes.arrivalTerminalsBox);
    return box.values.toList();
  }

  static Future<void> clearAll() async {
    final box = Hive.box<ArrivalModel>(HiveBoxes.arrivalTerminalsBox);
    await box.clear();
  }

  // Future<void> saveArrivalTerminals(List<ArrivalModel> arrivals) async {
  //   final box = await Hive.openBox<ArrivalModel>(boxName);
  //   await box.clear();
  //   for (final arrival in arrivals) {
  //     await box.put(arrival.id, arrival);
  //   }
  // }

  // Future<List<ArrivalModel>> getArrivalTerminals() async {
  //   final box = await Hive.openBox<ArrivalModel>('arrival_terminals');
  //   final items = box.values.toList();
  //   print("Retrieved from Hive: ${items.map((e) => e.name).toList()}");
  //   return items;
  // }

  // Future<void> preloadTestArrivalData() async {
  //   final box = await Hive.openBox<ArrivalModel>('arrival_terminals');
  //   if (box.isEmpty) {
  //     await box.addAll([
  //       ArrivalModel(id: '1', name: 'Shashamene', tariff: '500'),
  //       ArrivalModel(id: '2', name: 'Hawassa', tariff: '600'),
  //       ArrivalModel(id: '3', name: 'Jimma', tariff: '700'),
  //     ]);
  //   }
  // }
}

import 'package:hive/hive.dart';
import '../models/vehicle_model.dart';
import '../hive_boxes.dart';

class VehicleStorageService {
  
  static Future<void> saveVehicles(List<VehicleModel> vehicles) async {
    final box = Hive.box<VehicleModel>(HiveBoxes.vehiclesBox);
    await box.clear();
    for (var vehicle in vehicles) {
      await box.put(vehicle.id, vehicle);
    }
  }

  static List<VehicleModel> getVehicles() {
    final box = Hive.box<VehicleModel>(HiveBoxes.vehiclesBox);
    return box.values.toList();
  }

  static VehicleModel? getVehicleById(String id) {
    final box = Hive.box<VehicleModel>(HiveBoxes.vehiclesBox);
    return box.get(id);
  }

  // static Future<void> deleteVehicle(String id) async {
  //   final box = Hive.box<VehicleModel>(HiveBoxes.vehiclesBox);
  //   await box.delete(id);
  // }

  static Future<void> clearAll() async {
    final box = Hive.box<VehicleModel>(HiveBoxes.vehiclesBox);
    await box.clear();
  }
}

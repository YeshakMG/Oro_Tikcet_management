import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import 'models/vehicle_model.dart';

class HiveBoxes {
  static const String vehiclesBox = 'vehiclesBox';

  static Future<void> init() async {
    final appDir = await path_provider.getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDir.path);

    Hive.registerAdapter(VehicleModelAdapter());

    await Hive.openBox<VehicleModel>(vehiclesBox);
    
  }

}

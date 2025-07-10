import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:oro_ticket_app/data/locals/models/arrival_model.dart';
import 'package:oro_ticket_app/data/locals/models/departure_terminal_model.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import 'models/vehicle_model.dart';

class HiveBoxes {
  static const String vehiclesBox = 'vehiclesBox';
  static const String departureTerminalsBox = 'departureTerminalsBox';
  static const String arrivalTerminalsBox = 'arrivalTerminalsBox';
  static Future<void> init() async {
    final appDir = await path_provider.getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDir.path);

    Hive.registerAdapter(VehicleModelAdapter());
    await Hive.openBox<VehicleModel>(vehiclesBox);
    Hive.registerAdapter(DepartureTerminalModelAdapter());
    await Hive.openBox<DepartureTerminalModel>(departureTerminalsBox);
    Hive.registerAdapter(ArrivalModelAdapter());
    await Hive.openBox<ArrivalModel>(arrivalTerminalsBox);
  }
}

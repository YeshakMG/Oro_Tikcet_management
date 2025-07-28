import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:oro_ticket_app/data/locals/hive_boxes.dart';
import 'package:oro_ticket_app/data/locals/models/trip_model.dart';
import 'package:oro_ticket_app/data/locals/models/vehicle_model.dart';
import 'package:oro_ticket_app/data/locals/models/departure_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/models/arrival_terminal_model.dart';

class SyncController extends GetxController {
  final Box<TripModel> tripBox = Hive.box<TripModel>(HiveBoxes.tripBox);
  final tickets = <TripModel>[].obs;
  var searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadTicketsFromLocal();
  }

  void loadTicketsFromLocal() {
    tickets.value = tripBox.values.toList();
  }

  List<TripModel> get filteredTickets {
    if (searchQuery.value.isEmpty) return tickets;
    
    final vehicleBox = Hive.box<VehicleModel>(HiveBoxes.vehiclesBox);
    final departureBox = Hive.box<DepartureTerminalModel>(HiveBoxes.departureTerminalsBox);
    final arrivalBox = Hive.box<ArrivalTerminalModel>(HiveBoxes.arrivalTerminalsBox);
    
    return tickets.where((trip) {
      // Get vehicle details
      final vehicle = vehicleBox.values.firstWhere(
        (v) => v.id == trip.vehicleId,
        orElse: () => VehicleModel(
          id: "unknown",
          plateNumber: "unknown",
          plateRegion: "unknown",
          fleetType: "unknown",
          vehicleLevel: "Standard",
          associationName: "unknown",
          seatCapacity: 0,
          status: "unknown",
          arrivalTerminals: [],
          tariffs: [],
        ),
      );
      
      // Get departure terminal details
      final departureTerminal = departureBox.values.firstWhere(
        (t) => t.id == trip.departureTerminalId,
        orElse: () => DepartureTerminalModel(
          id: "unknown",
          name: "Unknown",
          status: "active",
        ),
      );
      
      // Get arrival terminal details
      final arrivalTerminal = arrivalBox.values.firstWhere(
        (t) => t.id == trip.arrivalTerminalId,
        orElse: () => ArrivalTerminalModel(
          id: "unknown",
          name: "Unknown",
          tariff: 0.0,
          distance: 0.0,
        ),
      );
      
      final query = searchQuery.value.toLowerCase();
      
      return vehicle.plateNumber.toLowerCase().contains(query) ||
             departureTerminal.name.toLowerCase().contains(query) ||
             arrivalTerminal.name.toLowerCase().contains(query) ||
             vehicle.associationName.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> refreshTickets() async {
    await Future.delayed(const Duration(seconds: 1));
    loadTicketsFromLocal();
    tickets.refresh();
  }

  Future<void> saveTicket(TripModel trip) async {
    await tripBox.add(trip);
    loadTicketsFromLocal();
  }
}

import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:oro_ticket_app/data/locals/hive_boxes.dart';
import 'package:oro_ticket_app/data/locals/models/trip_model.dart';

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
    return tickets.where((t) =>
      t.plateNumber.contains(searchQuery.value) ||
      t.departureTerminal.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
      t.arrivalTerminal.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
      t.employeeName.toLowerCase().contains(searchQuery.value.toLowerCase())
    ).toList();
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

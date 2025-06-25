import 'package:get/get.dart';
import '../../../data/models/ticket_model.dart';

class SyncController extends GetxController {
  final tickets = <Ticket>[
    Ticket(
      plateNumber: "23758",
      region: "Oromia",
      level: "Level 1",
      seatCapacity: 24,
      tripId: "1009",
      departure: "Addis Ababa",
      destination: "Mojjo",
      date: "2023-10-01",
      time: "08:00 AM",
      status: "Completed",
      employeeName: "John Doe",
    ),
    Ticket(
      plateNumber: "23759",
      region: "Oromia",
      level: "Level 2",
      seatCapacity: 15,
      tripId: "1010",
      departure: "Addis Ababa",
      destination: "Shasmane",
      date: "2023-10-02",
      time: "09:00 AM",
      status: "Completed",
      employeeName: "Jane Smith",
    ),
  ].obs;

  var searchQuery = ''.obs;

  List<Ticket> get filteredTickets {
    if (searchQuery.value.isEmpty) return tickets;
    return tickets.where((t) =>
      t.plateNumber.contains(searchQuery.value) ||
      t.tripId.contains(searchQuery.value) ||
      t.departure.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
      t.destination.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
      t.employeeName.toLowerCase().contains(searchQuery.value.toLowerCase())
    ).toList();
  }

  Future<void> refreshTickets() async {
    await Future.delayed(Duration(seconds: 1));
    tickets.refresh();
  }
}

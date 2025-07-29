import 'package:ethiopian_datetime/ethiopian_datetime.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:oro_ticket_app/widgets/app_scafold.dart';
import '../controller/sync_controller.dart';
import '../../ticketdetail/view/ticket_detail_view.dart';
import 'package:oro_ticket_app/data/locals/models/trip_model.dart';
import 'package:oro_ticket_app/data/locals/models/vehicle_model.dart';
import 'package:oro_ticket_app/data/locals/models/departure_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/models/arrival_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/hive_boxes.dart';
import '../../../data/models/ticket_model.dart';

class SyncView extends StatelessWidget {
  final SyncController controller = Get.put(SyncController());
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Sync",
      userName: "Employee Name",
      actions: const [
        Icon(Icons.more_horiz, color: Colors.white),
        SizedBox(width: 16),
      ],
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: Obx(() => RefreshIndicator(
                  onRefresh: controller.refreshTickets,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: controller.filteredTickets.length,
                    itemBuilder: (context, index) {
                      final ticket = controller.filteredTickets[index];
                      return _buildTicketCard(ticket);
                    },
                  ),
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (val) => controller.searchQuery.value = val,
              decoration: InputDecoration(
                hintText: "Search by Plate, Trip, Employee...",
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: controller.refreshTickets,
            icon: const Icon(Icons.sync),
            label: const Text("Sync"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(TripModel trip) {
    // Get vehicle details from vehicleId
    final vehicleBox = Hive.box<VehicleModel>(HiveBoxes.vehiclesBox);
    final currentDate = trip.dateAndTime;
    final ethDate = currentDate.convertToEthiopian();
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
    final departureBox =
        Hive.box<DepartureTerminalModel>(HiveBoxes.departureTerminalsBox);
    final departureTerminal = departureBox.values.firstWhere(
      (t) => t.id == trip.departureTerminalId,
      orElse: () => DepartureTerminalModel(
        id: "unknown",
        name: "Unknown",
        status: "active",
      ),
    );

    // Get arrival terminal details
    final arrivalBox =
        Hive.box<ArrivalTerminalModel>(HiveBoxes.arrivalTerminalsBox);
    final arrivalTerminal = arrivalBox.values.firstWhere(
      (t) => t.id == trip.arrivalTerminalId,
      orElse: () => ArrivalTerminalModel(
        id: "unknown",
        name: "Unknown",
        tariff: 0.0,
        distance: 0.0,
      ),
    );

    return GestureDetector(
      key: Key(trip.key?.toString() ??
          "unknown"), // Using key as a unique identifier

      onTap: () {
        Get.to(() => TicketDetailView(ticket: _convertToTicket(trip)),
            transition: Transition.rightToLeft,
            duration: const Duration(milliseconds: 300));
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_bus, color: Colors.green),
                  const SizedBox(width: 8),
                  Text("Plate: ${vehicle.plateNumber}",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text("Active"),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Association: ${vehicle.associationName}"),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                      child: Text(
                          "${departureTerminal.name} → ${arrivalTerminal.name}")),
                  const SizedBox(width: 8),
                  // Text(trip.dateAndTime.toString().substring(11, 16)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.layers, size: 16),
                  const SizedBox(width: 4),
                  Text(vehicle.vehicleLevel),
                  const SizedBox(width: 12),
                  const Icon(Icons.event_seat, size: 16),
                  const SizedBox(width: 4),
                  Text("${vehicle.seatCapacity} Seats"),
                ],
              ),
              SizedBox(
                height: 6,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 16),
                  Text("${ethDate.day}-${ethDate.month}-${ethDate.year}: ${ethDate.hour}:${ethDate.minute}"),
                  SizedBox(
                    width: 2,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to convert TripModel to Ticket for TicketDetailView
  Ticket _convertToTicket(TripModel trip) {
    // Get vehicle details from vehicleId
    final vehicleBox = Hive.box<VehicleModel>(HiveBoxes.vehiclesBox);
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
    final departureBox =
        Hive.box<DepartureTerminalModel>(HiveBoxes.departureTerminalsBox);
    final departureTerminal = departureBox.values.firstWhere(
      (t) => t.id == trip.departureTerminalId,
      orElse: () => DepartureTerminalModel(
        id: "unknown",
        name: "Unknown",
        status: "active",
      ),
    );

    // Get arrival terminal details
    final arrivalBox =
        Hive.box<ArrivalTerminalModel>(HiveBoxes.arrivalTerminalsBox);
    final arrivalTerminal = arrivalBox.values.firstWhere(
      (t) => t.id == trip.arrivalTerminalId,
      orElse: () => ArrivalTerminalModel(
        id: "unknown",
        name: "Unknown",
        tariff: 0.0,
        distance: 0.0,
      ),
    );

    return Ticket(
      plateNumber: vehicle.plateNumber,
      region: vehicle.plateRegion,
      level: vehicle.vehicleLevel,
      seatCapacity: vehicle.seatCapacity,
      tripId: trip.key?.toString() ?? "Unknown",
      departure: departureTerminal.name,
      destination: arrivalTerminal.name,
      date: trip.dateAndTime.toString().substring(0, 10),
      time: trip.dateAndTime.toString().substring(11, 16),
      status: "Active",
      employeeName:
          "Unknown", // TripModel doesn't have employeeName, using default
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:ethiopian_datetime/ethiopian_datetime.dart';

import '../controller/sync_controller.dart';
import 'package:oro_ticket_app/data/locals/models/trip_model.dart';
import 'package:oro_ticket_app/data/locals/models/vehicle_model.dart';
import 'package:oro_ticket_app/data/locals/models/departure_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/models/arrival_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/hive_boxes.dart';

class SyncView extends StatelessWidget {
  final SyncController controller = Get.put(SyncController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sync Tickets")),
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: Obx(() {
              final tickets = controller.filteredTickets;
              if (tickets.isEmpty) {
                return Center(child: Text("No matching tickets found."));
              }
              return RefreshIndicator(
                onRefresh: controller.refreshTickets,
                child: ListView.builder(
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    return _buildTicketCard(tickets[index]);
                  },
                ),
              );
            }),
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
                hintText: "Search by Plate No., Terminal, Association...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: controller.refreshTickets,
            icon: Icon(Icons.sync),
            label: Text("Sync"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(TripModel trip) {
    final vehicleBox = Hive.box<VehicleModel>(HiveBoxes.vehiclesBox);
    final departureBox = Hive.box<DepartureTerminalModel>(HiveBoxes.departureTerminalsBox);
    final arrivalBox = Hive.box<ArrivalTerminalModel>(HiveBoxes.arrivalTerminalsBox);

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

    final departure = departureBox.values.firstWhere(
      (d) => d.id == trip.departureTerminalId,
      orElse: () => DepartureTerminalModel(id: "unknown", name: "Unknown", status: "active"),
    );

    final arrival = arrivalBox.values.firstWhere(
      (a) => a.id == trip.arrivalTerminalId,
      orElse: () => ArrivalTerminalModel(id: "unknown", name: "Unknown", tariff: 0.0, distance: 0.0),
    );

    final ethDate = trip.dateAndTime.convertToEthiopian();

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("🚌 Plate: ${vehicle.plateNumber}", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text("📍 Route: ${departure.name} → ${arrival.name}"),
            SizedBox(height: 4),
            Text("🏢 Association: ${vehicle.associationName}"),
            SizedBox(height: 4),
            Text("💰 Tariff: ${trip.tariff} | Service: ${trip.serviceCharge} | Total: ${trip.totalPaid}"),
            SizedBox(height: 4),
            Text("🕒 ${ethDate.day}-${ethDate.month}-${ethDate.year}  ${ethDate.hour}:${ethDate.minute}"),
          ],
        ),
      ),
    );
  }
}

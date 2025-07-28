import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/widgets/app_scafold.dart';
import '../controller/sync_controller.dart';
import '../../ticketdetail/view/ticket_detail_view.dart';
import 'package:oro_ticket_app/data/locals/models/trip_model.dart';
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
    return GestureDetector(
      key: Key(trip.plateNumber), // Using plateNumber as a unique key

      onTap: () {
        // You may need to adapt the TicketDetailView to accept TripModel
        // or create a conversion function
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
                  Text("Plate: ${trip.plateNumber}",
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
                  Text("Association: ${trip.associationName}"),
                  Text(trip.dateTime.toString().substring(0, 10)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                      child:
                          Text("${trip.departureTerminal} → ${trip.arrivalTerminal}")),
                  const SizedBox(width: 8),
                  Text(trip.dateTime.toString().substring(11, 16)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.layers, size: 16),
                  const SizedBox(width: 4),
                  Text(trip.vehicleLevel),
                  const SizedBox(width: 12),
                  const Icon(Icons.event_seat, size: 16),
                  const SizedBox(width: 4),
                  Text("${trip.seatCapacity} Seats"),
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
    return Ticket(
      plateNumber: trip.plateNumber,
      region: trip.plateRegion,
      
      level: trip.vehicleLevel,
      seatCapacity: trip.seatCapacity,
      tripId: trip.key?.toString() ?? "Unknown",
      departure: trip.departureTerminal,
      destination: trip.arrivalTerminal,
      date: trip.dateTime.toString().substring(0, 10),
      time: trip.dateTime.toString().substring(11, 16),
      status: "Active",
      employeeName: trip.employeeName,
    );
  }
}

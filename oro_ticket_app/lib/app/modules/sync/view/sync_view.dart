import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:ethiopian_datetime/ethiopian_datetime.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/core/constants/typography.dart';
import 'package:oro_ticket_app/widgets/app_scafold.dart';

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
    return AppScaffold(
      title: "Sync Tickets",
      userName: '',
      actions: const [
        Icon(Icons.more_horiz, color: Colors.white),
        SizedBox(width: 16),
      ],
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
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: controller.refreshTickets,
            icon: Icon(Icons.sync, color: AppColors.card),
            label: Text("Sync", style: AppTextStyles.buttonSmall),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(TripModel trip) {
    final vehicleBox = Hive.box<VehicleModel>(HiveBoxes.vehiclesBox);
    final departureBox =
        Hive.box<DepartureTerminalModel>(HiveBoxes.departureTerminalsBox);
    final arrivalBox =
        Hive.box<ArrivalTerminalModel>(HiveBoxes.arrivalTerminalsBox);

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
      orElse: () => DepartureTerminalModel(
          id: "unknown", name: "Unknown", status: "active"),
    );

    final arrival = arrivalBox.values.firstWhere(
      (a) => a.id == trip.arrivalTerminalId,
      orElse: () => ArrivalTerminalModel(
          id: "unknown", name: "Unknown", tariff: 0.0, distance: 0.0),
    );

    final ethDate = trip.dateAndTime.convertToEthiopian();

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade100, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section with plate and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Plate: ${vehicle.plateRegion}${vehicle.plateNumber}",
                    style: AppTextStyles.buttonMediumB,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: trip.isSynced
                          ? Colors.green.shade300
                          : Colors.red.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      trip.isSynced ? "Synced" : "Not Synced",
                      style: AppTextStyles.buttonSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Divider(color: Colors.grey.shade300, height: 20),

              // Route information
              Row(
                children: [
                  Icon(Icons.place, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${departure.name} → ${arrival.name}",
                      style: AppTextStyles.buttonMediumB,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),

              // Association information
              Row(
                children: [
                  Icon(Icons.business, size: 18, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    vehicle.associationName,
                    style: AppTextStyles.buttonMediumB,
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.event_seat, size: 18, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Seat Number-${vehicle.seatCapacity.toString()}',
                    style: AppTextStyles.buttonMediumB,
                  ),
                ],
              ),
              SizedBox(height: 12),
              // Pricing section
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPriceItem("Tariff", trip.tariff.toString()),
                    _buildPriceItem("Service", trip.serviceCharge.toString()),
                    _buildPriceItem("Total", trip.totalPaid.toString(),
                        isTotal: true),
                  ],
                ),
              ),
              SizedBox(height: 12),

              // Date and time
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    "${ethDate.day}-${ethDate.month}-${ethDate.year} ${ethDate.hour}:${ethDate.minute.toString().padLeft(2, '0')}",
                    style: AppTextStyles.caption.copyWith(
                        color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceItem(String label, String value, {bool isTotal = false}) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.caption
              .copyWith(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.body2.copyWith(
            fontWeight: FontWeight.bold,
            color: isTotal ? Colors.green.shade800 : Colors.black,
          ),
        ),
      ],
    );
  }
}

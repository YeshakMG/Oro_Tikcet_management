import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/widgets/app_scafold.dart';

import '../controller/local_report_controller.dart';

class LocalReportView extends StatelessWidget {
  final LocalReportController controller = Get.put(LocalReportController());

  LocalReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Local Report',
      userName: 'Employee Name',
      currentBottomNavIndex: 2,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text("Download PDF"),
                  onPressed: () => controller.generatePDFReport(),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh"),
                  onPressed: () {
                    controller.loadTripsFromHive();
                    Get.snackbar("Refreshed", "Trip data reloaded");
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search (Departure, Arrival, Plate, User...)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: controller.searchTrips,
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            return Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 16,
                    headingRowHeight: 56,
                    columns: [
                      DataColumn(
                        label: Row(
                          children: [
                            const Text("Departure"),
                            IconButton(
                              icon: const Icon(Icons.sort),
                              onPressed: controller.sortByDepartureName,
                            ),
                          ],
                        ),
                      ),
                      const DataColumn(label: Text("Arrival")),
                      const DataColumn(label: Text("Plate Number")),
                      const DataColumn(label: Text("Region")),
                      const DataColumn(label: Text("Level")),
                      const DataColumn(label: Text("Association")),
                      DataColumn(
                        label: Row(
                          children: [
                            const Text("Price"),
                            IconButton(
                              icon: const Icon(Icons.sort),
                              onPressed: controller.sortByPrice,
                            ),
                          ],
                        ),
                      ),
                      const DataColumn(label: Text("Service Charge")),
                      const DataColumn(label: Text("Total Price")),
                      
                    ],
                    rows: controller.filteredTrips.map((trip) {
                      return DataRow(cells: [
                        DataCell(Text(trip.departureName)),
                        DataCell(Text(trip.arrivalName)),
                        DataCell(Text(trip.plateNumber)),
                        DataCell(Text(trip.plateRegion)),
                        DataCell(Text(trip.vehicleLevel)),
                        DataCell(Text(trip.associationName)),
                        DataCell(Text(trip.price.toStringAsFixed(2))),
                        DataCell(Text(trip.serviceCharge.toStringAsFixed(2))),
                        DataCell(Text(trip.totalPrice.toStringAsFixed(2))),
                        
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

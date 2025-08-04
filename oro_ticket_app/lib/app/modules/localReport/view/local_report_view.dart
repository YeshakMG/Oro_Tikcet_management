import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/widgets/app_scafold.dart';
import '../controller/local_report_controller.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';

class LocalReportView extends StatelessWidget {
  final LocalReportController controller = Get.put(LocalReportController());
  LocalReportView({super.key});

  Future<void> generatePDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Table.fromTextArray(
          headers: ['Trip ID', 'Departure', 'Destination', 'Plate', 'Date', 'Time'],
          data: controller.filteredReports.map((report) {
            return [
              report['tripId'],
              report['departure'],
              report['destination'],
              report['plate'],
              report['date'],
              report['time'],
            ];
          }).toList(),
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/trip_report.pdf");
    await file.writeAsBytes(await pdf.save());
    Get.snackbar("Success", "PDF downloaded to: ${file.path}");
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Local Report',
      userName: 'Employee Name',
      currentBottomNavIndex: 2,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text("Download"),
                  onPressed: generatePDF,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh"),
                  onPressed: () {
                    controller.loadTripsFromHive(); // Refresh only trip data
                    Get.snackbar("Refreshed", "Trip data has been reloaded");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: controller.searchReports,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by Trip ID, Departure, or Plate',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Obx(() => Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      columnSpacing: 16,
                      dataRowMinHeight: 48,
                      headingRowHeight: 56,
                      columns: [
                        DataColumn(
                          label: Row(
                            children: [
                              const Text("Trip ID"),
                              IconButton(
                                icon: const Icon(Icons.sort),
                                onPressed: controller.sortById,
                              ),
                            ],
                          ),
                        ),
                        DataColumn(
                          label: Row(
                            children: [
                              const Text("Departure"),
                              IconButton(
                                icon: const Icon(Icons.sort),
                                onPressed: controller.sortByArrival,
                              ),
                            ],
                          ),
                        ),
                        const DataColumn(label: Text("Destination")),
                        const DataColumn(label: Text("Plate")),
                        const DataColumn(label: Text("Date")),
                        const DataColumn(label: Text("Time")),
                        const DataColumn(label: Text("View")),
                      ],
                      rows: controller.filteredReports.map((report) {
                        return DataRow(cells: [
                          DataCell(Text(report['tripId'] ?? '')),
                          DataCell(Text(report['departure'] ?? '')),
                          DataCell(Text(report['destination'] ?? '')),
                          DataCell(Text(report['plate'] ?? '')),
                          DataCell(Text(report['date'] ?? '')),
                          DataCell(Text(report['time'] ?? '')),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.remove_red_eye_outlined),
                              onPressed: () {
                                // View logic here
                              },
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

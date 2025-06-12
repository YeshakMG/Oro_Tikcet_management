import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/local_report_controller.dart';

class LocalReportView extends GetView<LocalReportController> {
  const LocalReportView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Local Report"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text("Download"),
                  onPressed: () {
                    // Download logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.filter_list),
                  label: const Text("Filter"),
                  onPressed: () {
                    // Filter logic
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: controller.searchReports,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Obx(() => Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columns: [
                      DataColumn(
                        label: Row(
                          children: [
                            const Text("Trip ID"),
                            IconButton(
                              icon: const Icon(Icons.sort),
                              onPressed: controller.sortByArrival,
                            ),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Row(
                          children: [
                            const Text("Departure Location"),
                            IconButton(
                              icon: const Icon(Icons.sort),
                              onPressed: controller.sortById,
                            ),
                          ],
                        ),
                      ),
                      const DataColumn(label: Text("View")),
                    ],
                    rows: controller.filteredReports.map((report) {
                      return DataRow(cells: [
                        DataCell(Text(report['tripId']!)),
                        DataCell(Text(report['departure']!)),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.remove_red_eye_outlined),
                            onPressed: () {
                              // View logic
                            },
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

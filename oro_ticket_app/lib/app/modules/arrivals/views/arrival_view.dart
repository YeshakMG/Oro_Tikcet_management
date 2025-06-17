import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import '../controllers/arrival_controllers.dart';

class ArrivalLocationView extends GetView<ArrivalLocationController> {
  const ArrivalLocationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Arrival Location', style: TextStyle(color: Colors.white)),
        leading: const Icon(Icons.menu, color: Colors.white),
        actions: const [
          Icon(Icons.more_horiz, color: Colors.white),
          SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_alt_outlined),
                  label: const Text("Filter"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.backgroundAlt,
                    foregroundColor: AppColors.body,
                    elevation: 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: controller.filterLocations,
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: AppColors.backgroundAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() => SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(AppColors.cardAlt),
                    dataRowColor: MaterialStateProperty.all(AppColors.card),
                    columnSpacing: 16,
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Arrival Location')),
                    ],
                    rows: controller.Locations.map((loc) {
                      return DataRow(cells: [
                        DataCell(Text('${loc['id']}')),
                        DataCell(Text(loc['location'] ?? '')),
                      ]);
                    }).toList(),
                  ),
                )),
          ),
        ],
      ),
      
    );
  }
}

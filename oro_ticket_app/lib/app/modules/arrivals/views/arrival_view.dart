// lib/views/arrival_location_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/core/constants/typography.dart';
import 'package:oro_ticket_app/widgets/app_scafold.dart';
import '../controllers/arrival_controllers.dart';

class ArrivalLocationView extends StatelessWidget {
  final ArrivalLocationController controller =
      Get.put(ArrivalLocationController());

  ArrivalLocationView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Arrival Locations",
      userName: "Employee Name",
      actions: const [
        Icon(Icons.more_horiz, color: Colors.white),
        SizedBox(width: 16),
      ],
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: controller.syncLocations,
                    icon: const Icon(Icons.sync),
                    label: const Text("Sync"),
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
                        hintText: 'Search by name or town',
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
            Obx(() => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppColors.cardAlt),
                    dataRowColor: WidgetStateProperty.all(AppColors.card),
                    columnSpacing: 16,
                    columns: const [
                      DataColumn(
                          label:
                              Text('Name', style: AppTextStyles.buttonMedium)),
                      DataColumn(
                          label: Text('Distance',
                              style: AppTextStyles.buttonMedium)),
                      DataColumn(
                          label: Text('Tariff (ETB)',
                              style: AppTextStyles.buttonMedium),
                          numeric: true),
                    ],
                    rows: controller.filteredLocations.map((terminal) {
                      return DataRow(cells: [
                        DataCell(Text(terminal.name,
                            style: AppTextStyles.buttonMedium)),
                        DataCell(Text(
                            '${terminal.distance.toStringAsFixed(1)} km',
                            style: AppTextStyles.buttonMedium)),
                        DataCell(Text(terminal.tariff.toStringAsFixed(2),
                            style: AppTextStyles.buttonMedium)),
                      ]);
                    }).toList(),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

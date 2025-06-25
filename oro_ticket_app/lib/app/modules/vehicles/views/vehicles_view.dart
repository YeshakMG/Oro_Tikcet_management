import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/app/modules/vehicles/controllers/vehicles_controllers.dart';
import 'package:oro_ticket_app/widgets/app_scafold.dart';

class VehiclesView extends GetView<VehiclesController> {
  const VehiclesView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Vehicles',
      userName: 'Employee Name',
      showBottomNavBar: true,
      currentBottomNavIndex: 0,
      actions: const [
        Icon(Icons.more_horiz, color: Colors.white),
        SizedBox(width: 16),
      ],
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
                    onChanged: controller.filterVehicles,
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
                    headingRowColor: WidgetStateProperty.all(AppColors.cardAlt),
                    dataRowColor: WidgetStateProperty.all(AppColors.card),
                    columnSpacing: 16,
                    columns: const [
                      DataColumn(label: Text('Level')),
                      DataColumn(label: Text('Seat No')),
                      DataColumn(label: Text('Dep Terminal')),
                      DataColumn(label: Text('')),
                    ],
                    rows: controller.vehicles.map((vehicle) {
                      return DataRow(
                        cells: [
                          DataCell(Text(vehicle['level'] ?? '')),
                          DataCell(Text(vehicle['seat'] ?? '')),
                          DataCell(Text(vehicle['terminal'] ?? '')),
                          const DataCell(Icon(Icons.remove_red_eye_outlined,
                              color: AppColors.secondary)),
                        ],
                      );
                    }).toList(),
                  ),
                )),
          ),
        ],
      ),
    );
  }
}

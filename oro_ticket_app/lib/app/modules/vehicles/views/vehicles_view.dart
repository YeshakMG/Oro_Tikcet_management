import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/app/modules/vehicles/controllers/vehicles_controllers.dart';
import 'package:oro_ticket_app/app/modules/vehicles/bindings/vehicles_bindings.dart';

class VehiclesView extends GetView<VehiclesController> {
  const VehiclesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: const Icon(Icons.menu, color: Colors.white),
        title: const Text(
          'Vehicles',
          style: TextStyle(color: Colors.white),
        ),
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
                    headingRowColor: MaterialStateProperty.all(AppColors.cardAlt),
                    dataRowColor: MaterialStateProperty.all(AppColors.card),
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
                          const DataCell(Icon(Icons.remove_red_eye_outlined, color: AppColors.secondary)),
                        ],
                      );
                    }).toList(),
                  ),
                )),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.secondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_travel),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: '',
          ),
        ],
      ),
    );
  }
}

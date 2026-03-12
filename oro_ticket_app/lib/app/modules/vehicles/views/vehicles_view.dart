import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/app/modules/vehicles/controllers/vehicles_controllers.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/core/constants/typography.dart';
import 'package:oro_ticket_app/widgets/app_scafold.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class VehiclesView extends StatelessWidget {
  final VehiclesController controller = Get.put(VehiclesController());
  final RefreshController _refreshController = RefreshController();

  VehiclesView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final paddingHorizontal = size.width * 0.04; // 4% of screen width
    final paddingVertical = size.height * 0.02; // 2% of screen height

    return AppScaffold(
      title: 'Vehicles',
      userName: 'Employee',
      showBottomNavBar: true,
      currentBottomNavIndex: 0,
      actions: [
        Obx(() => IconButton(
          icon: controller.isSyncing.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.refresh, color: Colors.white),
          onPressed: controller.isSyncing.value ? null : controller.refreshVehicles,
          tooltip: 'Refresh vehicles',
        )),
      ],
      body: Column(
        children: [
          // Vehicles count header
          Obx(() => Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
                vertical: paddingVertical, horizontal: paddingHorizontal),
            color: AppColors.primary,
            child: Text(
              'Total Vehicles: ${controller.allVehicles.length}',
              style: AppTextStyles.body2.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          )),

          // 🔍 Full-width search bar
          Padding(
            padding: EdgeInsets.all(paddingHorizontal),
            child: TextField(
              onChanged: controller.filterVehicles,
              decoration: InputDecoration(
                hintText: 'Search by plate number or status',
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

          // Vehicles list
          Obx(() {
            if (controller.isLoading.value && controller.allVehicles.isEmpty) {
              return const Expanded(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (controller.errorMessage.isNotEmpty) {
              return Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(paddingHorizontal),
                    child: Text(
                      controller.errorMessage.value,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.buttonMedium
                          .copyWith(color: Colors.red),
                    ),
                  ),
                ),
              );
            }

            return Expanded(
              child: SmartRefresher(
                controller: _refreshController,
                onRefresh: () async {
                  await controller.refreshVehicles();
                  _refreshController.refreshCompleted();
                },
                child: ListView.builder(
                  itemCount: controller.filteredVehicles.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Header row
                      return Container(
                        color: AppColors.cardAlt,
                        padding: EdgeInsets.symmetric(
                            vertical: paddingVertical, horizontal: paddingHorizontal),
                        child: const Row(
                          children: [
                            Expanded(
                                child: Text("Plate Number",
                                    style: AppTextStyles.body2,
                                    textAlign: TextAlign.center)),
                            Expanded(
                                child: Text("Level",
                                    style: AppTextStyles.body2,
                                    textAlign: TextAlign.center)),
                            Expanded(
                                child: Text("Fleet Type",
                                    style: AppTextStyles.body2,
                                    textAlign: TextAlign.left)),
                          ],
                        ),
                      );
                    }

                    final vehicle = controller.filteredVehicles[index - 1];
                    final rowColor =
                        (index % 2 == 0) ? Colors.grey[100] : Colors.white;

                    return Container(
                      color: rowColor,
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Plate Number
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding:
                                    EdgeInsets.symmetric(horizontal: paddingHorizontal * 0.625),
                                child: Text(
                                  "${vehicle.plateRegion}${vehicle.plateNumber}",
                                  style: AppTextStyles.body2,
                                ),
                              ),
                            ),

                            // level
                            Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding:
                                    EdgeInsets.symmetric(horizontal: paddingHorizontal * 0.625),
                                child: Text(
                                  vehicle.vehicleLevel,
                                  style: AppTextStyles.caption,
                                ),
                              ),
                            ), // Fleet Type
                            Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding:
                                    EdgeInsets.symmetric(horizontal: paddingHorizontal * 0.9375),
                                child: Text(
                                  vehicle.fleetType,
                                  style: AppTextStyles.caption,
                                ),
                              ),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(paddingHorizontal * 0.5),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                  "Seat Capacity: ${vehicle.seatCapacity}",
                                  style: AppTextStyles.caption2),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(paddingHorizontal * 0.5),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  const Text("Status: ",
                                      style: AppTextStyles.caption2),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: paddingHorizontal * 0.625, vertical: paddingVertical * 0.5),
                                    decoration: BoxDecoration(
                                      color: (vehicle.status == "active")
                                          ? Colors.green
                                          : Colors.grey,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      vehicle.status ?? 'N/A',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

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
  final ScrollController _scrollController = ScrollController();

  VehiclesView({super.key}) {
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      controller.loadMoreVehicles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Vehicles',
      userName: 'Employee',
      showBottomNavBar: true,
      currentBottomNavIndex: 0,
      actions: [
        Obx(
          () => controller.isSyncing.value
              ? const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.sync),
                  onPressed: () => controller.loadLocalVehicles(),
                  color: AppColors.background,
                ),
        ),
      ],
      body: Column(
        children: [
          // 🔍 Full-width search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
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
                    padding: const EdgeInsets.all(16.0),
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
                  controller: _scrollController,
                  itemCount: controller.paginatedVehicles.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Header row
                      return Container(
                        color: AppColors.cardAlt,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        child: const Row(
                          children: [
                            Expanded(
                                child: Text("Plate Number",
                                    style: AppTextStyles.buttonMedium,
                                    textAlign: TextAlign.center)),
                            Expanded(
                                child: Text("Level",
                                    style: AppTextStyles.buttonMedium,
                                    textAlign: TextAlign.center)),
                            Expanded(
                                child: Text("Fleet Type",
                                    style: AppTextStyles.buttonMedium,
                                    textAlign: TextAlign.left)),
                          ],
                        ),
                      );
                    }

                    final vehicle = controller.paginatedVehicles[index - 1];
                    final rowColor =
                        (index % 2 == 0) ? Colors.grey[100] : Colors.white;

                    return Container(
                      color: rowColor,
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Plate Number
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  "${vehicle.plateRegion}${vehicle.plateNumber}",
                                  style: AppTextStyles.buttonMediumB,
                                ),
                              ),
                            ),

                            // level
                            Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  vehicle.vehicleLevel,
                                ),
                              ),
                            ), // Fleet Type
                            Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: Text(
                                  vehicle.fleetType,
                                  style: AppTextStyles.buttonMedium,
                                ),
                              ),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                  "Seat Capacity: ${vehicle.seatCapacity}",
                                  style: AppTextStyles.caption3),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  const Text("Status: ",
                                      style: AppTextStyles.caption3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
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

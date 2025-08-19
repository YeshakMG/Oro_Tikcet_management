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
  void dispose() {
    _scrollController.dispose();
    _refreshController.dispose();
    // super.dispose();
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
                ),
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: controller.filterVehicles,
                    decoration: InputDecoration(
                      hintText: 'Search by plate/status',
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
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      children: [
                        DataTable(
                          headingRowColor:
                              WidgetStateProperty.all(AppColors.cardAlt),
                          dataRowColor: WidgetStateProperty.all(AppColors.card),
                          columnSpacing: 16,
                          columns: const [
                            DataColumn(
                                label: Text('Plate No',
                                    style: AppTextStyles.buttonMedium)),
                            DataColumn(
                                label: Text('Seats',
                                    style: AppTextStyles.buttonMedium)),
                            DataColumn(
                                label: Text('Level',
                                    style: AppTextStyles.buttonMedium)),
                            DataColumn(
                                label: Text('Fleet Type',
                                    style: AppTextStyles.buttonMedium)),
                            DataColumn(
                                label: Text('Status',
                                    style: AppTextStyles.buttonMedium)),
                          ],
                          rows: controller.paginatedVehicles.map((vehicle) {
                            return DataRow(
                              cells: [
                                DataCell(Text(
                                  '${vehicle.plateRegion}-${vehicle.plateNumber}',
                                  style: AppTextStyles.buttonMediumB,
                                )),
                                DataCell(Text('${vehicle.seatCapacity}')),
                                DataCell(Text(vehicle.vehicleLevel)),
                                DataCell(Text(vehicle.fleetType)),
                                DataCell(Text(vehicle.status ?? 'N/A')),
                              ],
                            );
                          }).toList(),
                        ),
                        if (controller.isPageLoading.value)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          )
                        else if (controller.hasMore.value)
                          TextButton(
                            onPressed: () => controller.loadMoreVehicles(),
                            child: const Text('Load More',
                                style: AppTextStyles.buttonMediumB),
                          ),
                      ],
                    ),
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

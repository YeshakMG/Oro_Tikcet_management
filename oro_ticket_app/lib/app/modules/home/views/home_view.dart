import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oro_ticket_app/app/modules/home/controllers/home_controller.dart';
import 'package:oro_ticket_app/app/modules/sync/view/sync_view.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/core/constants/typography.dart';
import 'package:oro_ticket_app/widgets/app_scafold.dart';
import 'package:oro_ticket_app/widgets/daily_info_tile.dart';
import 'package:oro_ticket_app/widgets/dashboard_card.dart';
import 'package:oro_ticket_app/widgets/reset_dashboard_dialog.dart';

class HomeView extends StatelessWidget {
  final HomeController homeController = Get.put(HomeController());

  HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final paddingHorizontal = size.width * 0.04; // 4% of screen width
    final paddingVertical = size.height * 0.02; // 2% of screen height

    return Obx(() {
      final user = homeController.user.value;
      final companyName = homeController.companyName.value;

      return PopScope(

        child: AppScaffold(
          title: 'Oromia Transport Agency',
          userName: user?.fullName ?? 'Employee',
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Container(
                  color: AppColors.primary,
                  padding:
                      EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: paddingVertical * 2.5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // User & Company Info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            companyName.isNotEmpty
                                ? companyName
                                : 'Unknown Company',
                            style: AppTextStyles.subtitle1
                                .copyWith(color: Colors.white),
                          ),
                          SizedBox(height: paddingVertical * 0.2),
                          Text(
                            user?.fullName ?? 'Employee Name',
                            style: AppTextStyles.buttonMedium
                                .copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                      // Sync Button
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Get.to(() => SyncView());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.3),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: paddingHorizontal, vertical: paddingVertical),
                              textStyle: AppTextStyles.button,
                            ),
                            child: const Text('Sync'),
                          ),
                          IconButton(
                            onPressed: () async {
                              Get.snackbar(
                                'Syncing',
                                'Please wait...',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.blueGrey,
                                colorText: Colors.white,
                                showProgressIndicator: true,
                                isDismissible: false,
                              );

                              try {
                                final count = await homeController.syncTrips();
                                Get.back(); // Close loading snackbar
                                if (count > 0) {
                                  Get.snackbar(
                                    'Success',
                                    '$count trip(s) synced successfully!',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.green,
                                    colorText: Colors.white,
                                    duration: const Duration(seconds: 3),
                                  );
                                } else {
                                  Get.snackbar(
                                    'Info',
                                    'No trips to sync',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.orange,
                                    colorText: Colors.white,
                                    duration: const Duration(seconds: 3),
                                  );
                                }
                              } catch (e) {
                                Get.back(); // Close loading snackbar
                                Get.snackbar(
                                  'Error',
                                  e.toString(),
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                );
                              }
                            },
                            icon: const Icon(Icons.sync, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Dashboard Metrics
                DashboardCard(),
                SizedBox(height: paddingVertical * 2),

                // Daily Info Section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Daily Information",
                          style: AppTextStyles.heading3),
                      SizedBox(height: paddingVertical * 1.5),
                      Obx(() => DailyInfoTile(
                            icon: Icons.credit_card_rounded,
                            label: "Total Service Charge",
                            value:
                                "${homeController.serviceChargeToday.value.toStringAsFixed(2)} ETB",
                            onRefresh: () async {
                              await homeController.loadTodayServiceCharge();
                              Get.snackbar(
                                'Refreshed',
                                'Service charge updated',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: AppColors.primaryHover,
                                colorText: AppColors.background,
                              );
                            },
                          )),
                      SizedBox(height: paddingVertical * 1.25),
                      Obx(() => DailyInfoTile(
                            icon: Icons.calendar_month_sharp,
                            label: "Date",
                            value: homeController.ethiopianDate.value,
                          )),
                    ],
                  ),
                ),

                SizedBox(height: paddingVertical * 2.5),

                // Reset Dashboard Button
                Padding(
                  padding: EdgeInsets.all(paddingHorizontal),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("Reset Dashboard"),
                              content: const Text("Do you want to sync service charges before resetting?"),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(); // Close dialog
                                  },
                                  child: const Text("No"),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.of(context).pop(); // Close dialog immediately
                                    try {
                                      // Show loading snackbar
                                      Get.snackbar(
                                        'Syncing',
                                        'Please wait...',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.blueGrey,
                                        colorText: Colors.white,
                                        showProgressIndicator: true,
                                        isDismissible: false,
                                        duration: const Duration(seconds: 2), // Stay until manually closed
                                      );

                                      await homeController.syncServiceCharge();

                                      // Close loading snackbar before showing success
                                      Get.closeAllSnackbars();

                                      // If sync successful → reset dashboard
                                      homeController.resetDashboard();

                                      Get.snackbar(
                                        'Success',
                                        'Service charge synced and dashboard reset!',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.green,
                                        colorText: Colors.white,
                                        duration: const Duration(seconds: 3),
                                      );
                                    } catch (e) {
                                      // Close loading snackbar before showing error
                                      Get.closeAllSnackbars();

                                      // Sync failed → don't reset
                                      Get.snackbar(
                                        'Error',
                                        'Failed to sync: $e',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text("Yes"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: paddingVertical * 1.0),
                      ),
                      child: const Text(
                        "Reset Dashboard",
                        style: AppTextStyles.button,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

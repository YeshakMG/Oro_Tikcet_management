import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import 'package:oro_ticket_app/app/modules/home/controllers/home_controller.dart';
import 'package:oro_ticket_app/app/modules/sync/view/sync_view.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/core/constants/typography.dart';
import 'package:oro_ticket_app/data/locals/models/service_charge_model.dart';
import 'package:oro_ticket_app/data/locals/hive_boxes.dart';
import 'package:oro_ticket_app/widgets/app_scafold.dart';
import 'package:oro_ticket_app/widgets/daily_info_tile.dart';
import 'package:oro_ticket_app/widgets/dashboard_card.dart';
import 'package:oro_ticket_app/widgets/reset_dashboard_dialog.dart';

class HomeView extends StatelessWidget {
  final HomeController homeController = Get.put(HomeController());

  HomeView({super.key});

  @override
  Widget build(BuildContext context) {
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
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                          const SizedBox(height: 4),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
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
                                await homeController.syncTrips();
                                Get.closeCurrentSnackbar(); // Close loading snackbar
                                Get.snackbar(
                                  'Success',
                                  'Synced Successfully!',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColors.primaryHover,
                                  colorText: AppColors.background,
                                );
                              } catch (e) {
                                Get.closeCurrentSnackbar(); // Close loading snackbar
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
                const SizedBox(height: 16),
        
                // Daily Info Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Daily Information",
                          style: AppTextStyles.heading3),
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 10),
                      Obx(() => DailyInfoTile(
                            icon: Icons.calendar_month_sharp,
                            label: "Date",
                            value: homeController.ethiopianDate.value,
                          )),
                    ],
                  ),
                ),
        
                const SizedBox(height: 20),
        
                // Reset Dashboard Button
                Padding(
                                  padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final isSyncing = false.obs;
                      final showMessage = false.obs;
                      String message = '';

                      Get.dialog(
                        Obx(() => AlertDialog(
                          title: const Text("Reset Dashboard"),
                          content: isSyncing.value
                              ? const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text('Syncing service charges...'),
                                  ],
                                )
                              : showMessage.value
                                  ? Text(message)
                                  : const Text("Do you want to sync service charges before resetting?"),
                          actions: isSyncing.value
                              ? null // No actions during sync
                              : showMessage.value
                                  ? [
                                      TextButton(
                                        onPressed: () {
                                          print('Message acknowledged');
                                          Get.back();
                                        },
                                        child: const Text('OK'),
                                      ),
                                    ]
                                  : [
                                      TextButton(
                                        onPressed: () {
                                          print('Cancel clicked');
                                          Get.back();
                                        },
                                        child: const Text('No'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          print('Confirm clicked');

                                          // Check if there are service charges to sync
                                          final box = Hive.box<ServiceChargeModel>(HiveBoxes.serviceChargeBox);
                                          if (box.isEmpty) {
                                            print('No service charges found');
                                            // Show message in dialog for 3 seconds
                                            message = 'No service charges to sync';
                                            showMessage.value = true;

                                            // Auto-close after 3 seconds
                                            Future.delayed(const Duration(seconds: 3), () {
                                              if (Get.isDialogOpen ?? false) {
                                                Get.back();
                                              }
                                            });
                                            return;
                                          }

                                          print('Starting sync...');
                                          isSyncing.value = true;

                                          try {
                                            await homeController.syncServiceCharge();

                                            // If sync successful → reset dashboard
                                            homeController.resetDashboard();

                                            // Show success message in dialog for 3 seconds
                                            message = 'Service charge synced and dashboard reset successfully';
                                            showMessage.value = true;
                                            isSyncing.value = false;

                                            // Auto-close after 3 seconds
                                            Future.delayed(const Duration(seconds: 3), () {
                                              if (Get.isDialogOpen ?? false) {
                                                Get.back();
                                              }
                                            });
                                          } catch (e) {
                                            print('Sync failed: $e');
                                            isSyncing.value = false; // Reset loading state

                                            // Show error but keep dialog open for retry
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
                                        ),
                                        child: const Text('Yes'),
                                      ),
                                    ],
                        )),
                        barrierDismissible: !isSyncing.value && !showMessage.value,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

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
    return Obx(() {
      final user = homeController.user.value;
      final companyName = homeController.companyName.value;

      return AppScaffold(
        title: 'Oromia Transport Agency',
        userName: user?.fullName ?? 'Employee',
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              Container(
                color: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Employee & Company Info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          companyName.isNotEmpty
                              ? companyName
                              : 'Unknown Company',
                          style: AppTextStyles.subtitle1,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.fullName ?? 'Employee Name',
                          style: AppTextStyles.buttonMedium,
                        ),
                      ],
                    ),
                    // Sync Button
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Get.to(SyncView());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.3),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            elevation: 0,
                            textStyle: AppTextStyles.button,
                          ),
                          child: const Text('Sync'),
                        ),
                        IconButton(
                          onPressed: () {
                            Get.snackbar(
                              'Success',
                              "Synced Successfully!",
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColors.primaryHover,
                              colorText: AppColors.background,
                            );
                          },
                          icon: Icon(Icons.sync, color: AppColors.cardAlt),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Dashboard Cards
              DashboardCard(),
              const SizedBox(height: 16),

              // Daily Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Daily Information", style: AppTextStyles.heading3),
                    SizedBox(height: 12),
                    DailyInfoTile(
                      icon: Icons.credit_card_rounded,
                      label: "Total Service Charge",
                      value: "Balance: 14,423 ETB",
                    ),
                    SizedBox(height: 10),
                    DailyInfoTile(
                      icon: Icons.calendar_month_sharp,
                      label: "Date",
                      value: "09/23/2025",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Reset Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.dialog(
                        ResetDashboardDialog(
                          onReset: () {
                            homeController.resetDashboard();
                            Get.snackbar(
                              'Success',
                              'Dashboard reset successfully',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColors.primaryHover,
                            );
                          },
                        ),
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
      );
    });
  }
}

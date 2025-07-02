import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:oro_ticket_app/app/modules/home/controllers/home_controller.dart';
import 'package:oro_ticket_app/app/modules/sync/view/sync_view.dart';
import 'package:oro_ticket_app/app/modules/ticket/view/ticket_view.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/core/constants/typography.dart';
import 'package:oro_ticket_app/widgets/app_scafold.dart';
import 'package:oro_ticket_app/widgets/daily_info_tile.dart';
import 'package:oro_ticket_app/widgets/dashboard_card.dart';

class HomeView extends StatelessWidget {
  final HomeController homeController = HomeController();
  HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Oromia Transport Agency',
      userName: 'Employee Name',
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Company Name', style: AppTextStyles.companyName),
                      SizedBox(height: 4),
                      Text('Employee Name', style: AppTextStyles.subtitle1),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Get.to(SyncView());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
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
                    ],
                  ),
                ],
              ),
            ),

            // Rest of your content
            const DashboardCard(),
            const SizedBox(height: 16),

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

            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
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
  }
}

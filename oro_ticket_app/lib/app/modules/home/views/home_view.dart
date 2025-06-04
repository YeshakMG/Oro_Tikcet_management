import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/core/constants/typography.dart';
import 'package:oro_ticket_app/widgets/bottom_navbar.dart';
import 'package:oro_ticket_app/widgets/custom_drawer.dart';
import 'package:oro_ticket_app/widgets/daily_info_tile.dart';
import 'package:oro_ticket_app/widgets/dashboard_card.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      drawer: CustomDrawer(
        userName: 'Tensae Tefera',
        onItemSelected: (item) {
          switch (item) {
            case 'Vehicles':
              // Handle logout
              break;
            // Handle other cases
          }
        },
      ),
      bottomNavigationBar: const BottomNavBar(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  const Text('OTA', style: AppTextStyles.subtitle1),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text("Sync",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  )
                ],
              ),
            ),

            // Agent Info Section
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.only(left: 16, bottom: 20),
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('GUZO ET', style: AppTextStyles.heading1),
                  Text('Agent Name', style: AppTextStyles.button),
                ],
              ),
            ),

            // Card
            const DashboardCard(),

            const SizedBox(height: 16),

            // Daily Information Section
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
                    value: "Balance: 14423 ETB",
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

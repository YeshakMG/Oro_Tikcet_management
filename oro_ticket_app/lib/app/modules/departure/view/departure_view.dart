import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/app/modules/departure/controllers/departure_controllers.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/core/constants/typography.dart';
import 'package:oro_ticket_app/widgets/app_scafold.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class DepartureView extends GetView<DepartureControllers> {
  final DepartureControllers controller = Get.put(DepartureControllers());
  final RefreshController _refreshController = RefreshController();

  DepartureView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final paddingHorizontal = size.width * 0.04; // 4% of screen width
    final paddingVertical = size.height * 0.02; // 2% of screen height

    return AppScaffold(
      title: 'Departure',
      userName: 'Employee Name',
      showBottomNavBar: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () async {
            await controller.refreshTerminal();
            Get.snackbar(
              "Refreshed",
              "Departure terminal data refreshed",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green.withValues(alpha: 0.8),
              colorText: Colors.white,
            );
          },
        ),
        SizedBox(width: paddingHorizontal),
      ],
      body: Padding(
        padding: EdgeInsets.all(paddingHorizontal),
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                final terminal = controller.terminal.value;

                return SmartRefresher(
                  controller: _refreshController,
                  onRefresh: () async {
                    controller.loadTerminal();
                    _refreshController.refreshCompleted();
                  },
                  child: terminal == null
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: size.height * 0.15), // Responsive height
                            const Center(child: Text('No terminal found')),
                          ],
                        )
                      : ListView(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                  vertical: paddingVertical, horizontal: paddingHorizontal),
                              color: AppColors.cardAlt,
                              child: const Text(
                                'Departure Terminal Name',
                                style: AppTextStyles.buttonMedium,
                              ),
                            ),
                            SizedBox(height: size.height * 0.01), // Responsive spacing
                            Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: paddingVertical, horizontal: paddingHorizontal),
                              color: AppColors.card,
                              child: Text(
                                terminal.name,
                                style: AppTextStyles.buttonMedium,
                              ),
                            ),
                          ],
                        ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

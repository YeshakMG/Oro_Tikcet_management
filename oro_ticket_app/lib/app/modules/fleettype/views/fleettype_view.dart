import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/widgets/app_scafold.dart';
import '../controllers/fleettype_controllers.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';

class FleetTypeView extends StatelessWidget {
  const FleetTypeView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final paddingHorizontal = size.width * 0.04; // 4% of screen width
    final paddingVertical = size.height * 0.02; // 2% of screen height
    final spacing = size.width * 0.03; // 3% for spacing

    final controller = Get.find<FleetTypeController>();

    return AppScaffold(
      title: 'Fleet Type',
      userName: 'Employee Name',
      showBottomNavBar: true,
      actions: [
        const Icon(Icons.more_horiz, color: Colors.white),
        SizedBox(width: paddingHorizontal),
      ],
      body: Padding(
        padding: EdgeInsets.all(paddingHorizontal),
        child: Column(
          children: [
            // Filter & Search Bar
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_alt_outlined),
                  label: const Text('Filter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardAlt,
                    foregroundColor: AppColors.primary,
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: TextField(
                    onChanged: controller.filterFleetType,
                    decoration: const InputDecoration(
                      hintText: 'Search',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing),
            // Table Header
            Container(
              color: AppColors.backgroundAlt,
              padding: EdgeInsets.symmetric(vertical: paddingVertical * 0.5, horizontal: paddingHorizontal * 0.5),
              child: Row(
                children: const [
                  Expanded(flex: 2, child: Text('Name')),
                  Expanded(flex: 2, child: Text('Level')),
                  Expanded(flex: 1, child: Text('Total seat')),
                ],
              ),
            ),
            // Table Data
            Expanded(
              child: Obx(() => ListView.builder(
                    itemCount: controller.fleetTypes.length,
                    itemBuilder: (_, index) {
                      final item = controller.fleetTypes[index];
                      return Container(
                        padding: EdgeInsets.symmetric(
                            vertical: paddingVertical, horizontal: paddingHorizontal * 0.5),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppColors.divider),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: Text(item['name'] ?? '')),
                            Expanded(flex: 2, child: Text(item['level'] ?? '')),
                            Expanded(
                                flex: 1,
                                child: Text(item['totalSeat'].toString())),
                          ],
                        ),
                      );
                    },
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

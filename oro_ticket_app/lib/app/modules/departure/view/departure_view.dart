import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/app/modules/departure/controllers/departure_controllers.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/core/constants/typography.dart';
import 'package:oro_ticket_app/widgets/app_scafold.dart';

class DepartureView extends GetView<DepartureControllers> {
  final DepartureControllers controller = Get.put(DepartureControllers());

  DepartureView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Departure',
      userName: 'Employee Name',
      // currentBottomNavIndex: 0,
      showBottomNavBar: true,
      actions: const [
        Icon(Icons.more_horiz, color: Colors.white),
        SizedBox(width: 16),
      ],
      body: Obx(() {
        final terminal = controller.terminal.value;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.background),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: controller.loadTerminal,
                      icon: const Icon(Icons.sync),
                      label: const Text("Sync"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.backgroundAlt,
                        foregroundColor: AppColors.body,
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search',
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
              const SizedBox(height: 16),
              terminal == null
                  ? const Text('No terminal found')
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor:
                            WidgetStateProperty.all(AppColors.cardAlt),
                        dataRowColor: WidgetStateProperty.all(AppColors.card),
                        columns: const [
                          DataColumn(
                              label: Text(
                            'No',
                            style: AppTextStyles.buttonMedium,
                          )),
                          DataColumn(
                              label: Text('Departure Terminal Name',
                                  style: AppTextStyles.buttonMedium)),
                        ],
                        rows: [
                          DataRow(cells: [
                            const DataCell(
                                Text('', style: AppTextStyles.buttonMedium)),
                            DataCell(Text(terminal.name,
                                style: AppTextStyles.buttonMedium)),
                          ])
                        ],
                      ),
                    ),
            ],
          ),
        );
      }),
    );
  }
}

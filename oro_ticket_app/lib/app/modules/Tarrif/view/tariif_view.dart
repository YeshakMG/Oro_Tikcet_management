// tariff_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/tarrif_controller.dart';

class TariffView extends StatelessWidget {
  final TariffController controller = Get.find<TariffController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tariff Management')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() => DropdownButton<String>(
                  value: controller.selectedArrival.value.isEmpty
                      ? null
                      : controller.selectedArrival.value,
                  hint: Text('Select Arrival'),
                  onChanged: (value) {
                    if (value != null) controller.filterTariffs(value);
                  },
                  items: controller.arrivals
                      .map((arrival) => DropdownMenuItem(
                            value: arrival,
                            child: Text(arrival),
                          ))
                      .toList(),
                )),
            SizedBox(height: 20),
            Obx(() => Expanded(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Level')),
                      DataColumn(label: Text('Fleet Category')),
                    ],
                    rows: controller.tariffs
                        .map((tariff) => DataRow(cells: [
                              DataCell(Text(tariff['level'] ?? '')),
                              DataCell(Text(tariff['fleet_category'] ?? '')),
                            ]))
                        .toList(),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/app/data/models/ticket_model.dart';
import 'package:oro_ticket_app/app/modules/ticketdetail/view/ticket_detail_view.dart';
import 'package:oro_ticket_app/widgets/app_scafold.dart';
import '../controller/ticket_controller.dart';

class TicketView extends StatelessWidget {
  final TicketController controller = Get.put(TicketController());
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Ticket",
      userName: "Employee Name",
      currentBottomNavIndex: 1,
      showBottomNavBar: true,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 8,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Obx(() => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 30,
                      child: Icon(Icons.directions_bus, color: Colors.green),
                    ),
                    const SizedBox(height: 8),
                    Text(controller.agencyName.value,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Divider(thickness: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(children: [
                          Text(controller.locationFrom.value),
                          Text(controller.timeFrom.value),
                        ]),
                        const Icon(Icons.directions_bus),
                        Column(children: [
                          Text(controller.locationTo.value),
                          Text(controller.timeTo.value),
                        ]),
                      ],
                    ),
                    const Divider(thickness: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(3),
                          1: FlexColumnWidth(4),
                        },
                        children: [
                          _buildTableRow(
                              "Plate Number", controller.plateNumber.value),
                          _buildTableRow("Seat No.", controller.seatNo.value),
                          _buildTableRow(
                              "Date and Time", controller.dateTime.value),
                          _buildTableRow("KM", controller.km.value),
                          _buildTableRow("Tariff", controller.tariff.value),
                          _buildTableRow(
                              "Service Charge", controller.serviceCharge.value),
                        ],
                      ),
                    ),
                    const Divider(),
                    Text("TOTAL: ${controller.total.value}",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(controller.employeeName.value),
                    Text("Ticket Status : ${controller.ticketStatus.value}"),
                    const SizedBox(height: 16),
                    Container(
                      height: 60,
                      width: 200,
                      color: Colors.black12,
                      alignment: Alignment.center,
                      child: const Text("||| ||| |||| || |||",
                          style: TextStyle(fontSize: 24, letterSpacing: 4)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.check),
                          label: const Text("Done"),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.print),
                          label: const Text("Print"),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[900]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                )),
          ),
        ),
      ),
    );
  }

  TableRow _buildTableRow(String title, String value) {
    return TableRow(children: [
      Padding(padding: const EdgeInsets.all(4.0), child: Text(title)),
      Padding(padding: const EdgeInsets.all(4.0), child: Text(value)),
    ]);
  }
}

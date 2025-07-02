import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/ticket_controller.dart';
import '../binding/ticket_binding.dart';




class TicketView extends StatefulWidget {
  @override
  State<TicketView> createState() => _TicketViewState();
}

class _TicketViewState extends State<TicketView> {
  final _ticketController = Get.find<TicketController>();

  final List<String> departures = ['Adama', 'Addis Ababa', 'Jimma'];
  final List<String> destinations = ['Nekemet', 'Mojjo', 'Dire Dawa'];

  String? selectedDeparture;
  String? selectedDestination;
  String plateInput = '';
  bool showTicket = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[700],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() => Text(
                        _ticketController.agencyName.value,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22),
                      )),
                  ElevatedButton(
                    onPressed: () {},
                    child: Text("Sync"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[300]),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: ListView(
                  children: [
                    Text(
                      "Secure your bus tickets without the hassle of going to our agent.",
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 10),
                    Text("Complete the form below to purchase EGOBUS tickets"),
                    SizedBox(height: 20),

                    // Departure Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedDeparture,
                      hint: Text('Departure point default'),
                      onChanged: (val) => setState(() {
                        selectedDeparture = val;
                      }),
                      items: departures
                          .map((loc) => DropdownMenuItem(
                              value: loc, child: Text(loc)))
                          .toList(),
                    ),
                    SizedBox(height: 10),

                    // Destination Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedDestination,
                      hint: Text('Select destination point'),
                      onChanged: (val) => setState(() {
                        selectedDestination = val;
                      }),
                      items: destinations
                          .map((loc) => DropdownMenuItem(
                              value: loc, child: Text(loc)))
                          .toList(),
                    ),
                    SizedBox(height: 10),

                    // Plate Number Input
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Plate Number',
                        prefixIcon: Icon(Icons.directions_bus),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => plateInput = val,
                    ),
                    SizedBox(height: 20),

                    // Check Ticket Button
                    ElevatedButton(
                      onPressed: () {
                        if (selectedDeparture != null &&
                            selectedDestination != null &&
                            plateInput.isNotEmpty) {
                          setState(() => showTicket = true);
                        } else {
                          Get.snackbar("Invalid Input",
                              "Please complete all fields");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: Size(double.infinity, 48),
                      ),
                      child: Text("Check Ticket"),
                    ),

                    SizedBox(height: 30),

                    // Ticket Info View
                    if (showTicket)
                      Obx(() => Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.green),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.directions_bus),
                                    SizedBox(width: 8),
                                    Text("Bus Number: OR ${_ticketController.plateNumber.value}",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Spacer(),
                                    ElevatedButton(
                                      onPressed: () {
                                        Get.to(() => TicketPrintPage());
                                      },
                                      child: Text("Confirm"),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green),
                                    )
                                  ],
                                ),
                                Divider(),
                                Text(
                                    "${_ticketController.locationFrom.value} ➜ ${_ticketController.locationTo.value}"),
                                Text("Time: ${_ticketController.timeFrom.value} - ${_ticketController.timeTo.value}"),
                                Text("Seat: ${_ticketController.seatNo.value}"),
                                Text("Date: ${_ticketController.dateTime.value}"),
                                Text("Distance: ${_ticketController.km.value}"),
                                Text("Fare: ${_ticketController.tariff.value}"),
                                Text("Service Charge: ${_ticketController.serviceCharge.value}"),
                                Text("Total: ${_ticketController.total.value}"),
                                Text("Ticket Status: ${_ticketController.ticketStatus.value}"),
                                Text("Employee: ${_ticketController.employeeName.value}"),
                              ],
                            ),
                          ))
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ Dummy Print Page
class TicketPrintPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Print Ticket"), backgroundColor: Colors.green),
      body: Center(
        child: Text("🖨️ This is your print page.", style: TextStyle(fontSize: 20)),
      ),
    );
  }
}

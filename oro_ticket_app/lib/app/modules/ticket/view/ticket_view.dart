import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/core/constants/typography.dart';
import 'package:oro_ticket_app/widgets/app_scafold.dart';
import '../controller/ticket_controller.dart';
import '../binding/ticket_binding.dart';

class TicketView extends StatefulWidget {
  @override
  State<TicketView> createState() => _TicketViewState();
}

class _TicketViewState extends State<TicketView> {
  final _ticketController = Get.put(TicketController());

  final List<String> departures = ['Adama', 'Addis Ababa', 'Jimma'];
  final List<String> destinations = ['Nekemet', 'Mojjo', 'Dire Dawa'];

  String? selectedDeparture;
  String? selectedDestination;
  String plateInput = '';
  bool showTicket = false;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Ticket",
      userName: "Employee Name",
      currentBottomNavIndex: 1,
      showBottomNavBar: true,
      actions: const [
        Icon(Icons.more_horiz, color: Colors.white),
        SizedBox(width: 16),
      ],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                        .map((loc) =>
                            DropdownMenuItem(value: loc, child: Text(loc)))
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
                        .map((loc) =>
                            DropdownMenuItem(value: loc, child: Text(loc)))
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

                        _ticketController.plateNumber.value = plateInput;
                        _ticketController.locationFrom.value =
                            selectedDeparture!;
                        _ticketController.locationTo.value =
                            selectedDestination!;
                      } else {
                        Get.snackbar(
                          "Invalid Input",
                          "Please complete all fields",
                          backgroundColor: AppColors.error,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: Size(double.infinity, 48),
                    ),
                    child: Text(
                      "Check Ticket",
                      style: AppTextStyles.button,
                    ),
                  ),
                  SizedBox(height: 30),

                  if (showTicket)
                    Obx(() => Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Bus number + Confirm button
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    child: Icon(Icons.directions_bus,
                                        color: AppColors.primary),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                      "Bus Number\nOR ${_ticketController.plateNumber.value}",
                                      style: AppTextStyles.subtitle3),
                                  Spacer(),
                                  ElevatedButton(
                                    onPressed: () {
                                      Get.to(() => TicketPrintPage());
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                    ),
                                    child: Text(
                                      "Confirm",
                                      style: AppTextStyles.buttonSmall,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),

                              // Route Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        _ticketController.locationFrom.value,
                                        style: AppTextStyles.body1.copyWith(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 4),
                                      Text(_ticketController.timeFrom.value,
                                          style: AppTextStyles.body2),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Icon(Icons.directions_bus,
                                          size: 24, color: AppColors.primary),
                                      Container(
                                        height: 1,
                                        width: 100,
                                        margin:
                                            EdgeInsets.symmetric(vertical: 4),
                                        color: Colors.grey.shade300,
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        _ticketController.locationTo.value,
                                        style: AppTextStyles.body1.copyWith(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 4),
                                      Text(_ticketController.timeTo.value,
                                          style: AppTextStyles.body2),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              _TicketBadge(
                                icon: Icons.date_range,
                                label: _ticketController.dateTime.value,
                              ),
                              SizedBox(height: 16),
                              // Seat and Level badges
                              Row(
                                children: [
                                  _TicketBadge(
                                      icon: Icons.event_seat,
                                      label:
                                          "${_ticketController.seatNo.value} Seat"),
                                  SizedBox(width: 12),
                                  _TicketBadge(
                                      icon: Icons.diamond,
                                      label: _ticketController.level.value),
                                ],
                              ),
                            ],
                          ),
                        ))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ Dummy Print Page
class TicketPrintPage extends StatelessWidget {
  const TicketPrintPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text("Print Ticket"), backgroundColor: Colors.green),
      body: Center(
        child: Text("🖨️ This is your print page.",
            style: TextStyle(fontSize: 20)),
      ),
    );
  }
}

class _TicketBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TicketBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/core/constants/typography.dart';
import 'package:oro_ticket_app/data/locals/models/vehicle_model.dart';
import 'package:oro_ticket_app/data/locals/models/departure_terminal_model.dart';
import 'package:oro_ticket_app/widgets/app_scafold.dart';
import '../controller/ticket_controller.dart';

class TicketView extends StatefulWidget {
  @override
  State<TicketView> createState() => _TicketViewState();
}

class _TicketViewState extends State<TicketView> {
  final _ticketController = Get.put(TicketController());

  final List<String> destinations = ['Nekemet', 'Mojjo', 'Dire Dawa'];

  String? selectedDeparture;
  String? selectedDestination;
  String plateInput = '';
  List<VehicleModel> suggestions = [];
  final plateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDefaultDeparture();
  }

  void _loadDefaultDeparture() {
    final terminalBox = Hive.box<DepartureTerminalModel>('departureTerminalsBox');
    final terminal = terminalBox.values.firstOrNull;

    if (terminal != null) {
      setState(() {
        selectedDeparture = terminal.name;
        _ticketController.locationFrom.value = terminal.name;
      });
    }
  }

  void _onPlateInputChanged(String input) {
    final vehicleBox = Hive.box<VehicleModel>('vehiclesBox');

    final filtered = vehicleBox.values
        .where((v) => v.plateNumber.toLowerCase().contains(input.toLowerCase()))
        .toList();

    setState(() {
      plateInput = input;
      suggestions = filtered;
    });
  }

  bool get _canShowTicket =>
      plateInput.isNotEmpty && selectedDeparture != null && selectedDestination != null;

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
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text("Ejensii geejjibaa Oromiyaa"),
                  SizedBox(height: 20),

                  // Departure Terminal (read-only)
                  TextFormField(
                    readOnly: true,
                    initialValue: selectedDeparture ?? 'Loading...',
                    decoration: InputDecoration(
                      labelText: 'Departure Terminal',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),

                  // Destination
                  DropdownButtonFormField<String>(
                    value: selectedDestination,
                    hint: Text('Select destination point'),
                    onChanged: (val) => setState(() => selectedDestination = val),
                    items: destinations
                        .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
                        .toList(),
                  ),
                  SizedBox(height: 10),

                  // Plate input with suggestion
                  TextFormField(
                    controller: plateController,
                    decoration: InputDecoration(
                      labelText: 'Plate Number',
                      prefixIcon: Icon(Icons.directions_bus),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _onPlateInputChanged,
                  ),
                  if (suggestions.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: suggestions.length,
                        itemBuilder: (context, index) {
                          final vehicle = suggestions[index];
                          return ListTile(
                            title: Text(vehicle.plateNumber),
                            subtitle: Text('${vehicle.plateRegion} • ${vehicle.fleetType}'),
                            onTap: () {
                              plateController.text = vehicle.plateNumber;
                              plateInput = vehicle.plateNumber;
                              suggestions.clear();

                              _ticketController.plateNumber.value = vehicle.plateNumber;
                              _ticketController.level.value = vehicle.vehicleLevel;
                              _ticketController.seatNo.value = vehicle.seatCapacity.toString();

                              setState(() {}); // Refresh suggestion UI
                            },
                          );
                        },
                      ),
                    ),
                  SizedBox(height: 20),

                  // Check Ticket Button
                  ElevatedButton(
                    onPressed: _canShowTicket
                        ? () {
                            _ticketController.locationTo.value = selectedDestination!;
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: Size(double.infinity, 48),
                    ),
                    child: Text("Check Ticket", style: AppTextStyles.button),
                  ),
                  SizedBox(height: 30),

                  if (_canShowTicket) Obx(() => _TicketCard()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final _ticketController = Get.find<TicketController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Icon(Icons.directions_bus, color: AppColors.primary),
              ),
              SizedBox(width: 8),
              Text("Bus Number\nOR ${_ticketController.plateNumber.value}",
                  style: AppTextStyles.subtitle3),
              Spacer(),
              ElevatedButton(
                onPressed: () => Get.to(() => TicketPrintPage()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text("Confirm", style: AppTextStyles.buttonSmall),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LocationColumn(_ticketController.locationFrom.value, _ticketController.timeFrom.value),
              Icon(Icons.directions_bus, size: 24, color: AppColors.primary),
              _LocationColumn(_ticketController.locationTo.value, _ticketController.timeTo.value),
            ],
          ),
          SizedBox(height: 16),
          _TicketBadge(icon: Icons.date_range, label: _ticketController.dateTime.value),
          SizedBox(height: 16),
          Row(
            children: [
              _TicketBadge(icon: Icons.event_seat, label: "${_ticketController.seatNo.value} Seat"),
              SizedBox(width: 12),
              _TicketBadge(icon: Icons.diamond, label: _ticketController.level.value),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationColumn extends StatelessWidget {
  final String title;
  final String time;

  const _LocationColumn(this.title, this.time);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text(time, style: AppTextStyles.body2),
      ],
    );
  }
}

class _TicketBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TicketBadge({required this.icon, required this.label});

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
              style: TextStyle(fontSize: 12, color: Colors.grey[800], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class TicketPrintPage extends StatelessWidget {
  const TicketPrintPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Print Ticket"), backgroundColor: Colors.green),
      body: Center(child: Text("🖨️ This is your print page.", style: TextStyle(fontSize: 20))),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/core/constants/typography.dart';
import 'package:oro_ticket_app/data/locals/models/vehicle_model.dart';
import 'package:oro_ticket_app/data/locals/models/departure_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/models/arrival_terminal_model.dart';
import 'package:oro_ticket_app/widgets/app_scafold.dart';
import '../controller/ticket_controller.dart';

class TicketView extends StatefulWidget {
  @override
  State<TicketView> createState() => _TicketViewState();
}

class _TicketViewState extends State<TicketView> {
  final _ticketController = Get.put(TicketController());

  List<ArrivalTerminalModel> arrivalTerminals = [];
  ArrivalTerminalModel? selectedArrival;

  String? selectedDeparture;
  String plateInput = '';
  List<VehicleModel> suggestions = [];
  final plateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDefaultDeparture();
    _loadArrivalTerminals();
  }

  void _loadArrivalTerminals() {
    final box = Hive.box<ArrivalTerminalModel>('arrivalTerminalsBox');
    setState(() {
      arrivalTerminals = box.values.toList();
    });
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
      plateInput.isNotEmpty && selectedDeparture != null && selectedArrival != null;

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
                  Text("Oromia Transport Agency"),
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
                  DropdownButtonFormField<ArrivalTerminalModel>(
                    value: selectedArrival,
                    hint: Text('Select destination'),
                    onChanged: (val) {
                      setState(() {
                        selectedArrival = val;
                      });
                      if (val != null) {
                        _ticketController.locationTo.value = val.name;
                        _ticketController.km.value = "${val.distance.toStringAsFixed(1)} km";
                        _ticketController.tariff.value = "${val.tariff.toStringAsFixed(2)} ETB";
                        _ticketController.calculateCharges(val.tariff);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Destination Terminal',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                    items: arrivalTerminals
                        .map((loc) => DropdownMenuItem(
                              value: loc,
                              child: Text(loc.name),
                            ))
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
                              _ticketController.level.value = vehicle.vehicleLevel;
                              _ticketController.associations.value = vehicle.associationName;
                              _ticketController.region.value = vehicle.plateRegion;

                              setState(() {}); // Refresh suggestion UI
                            },
                          );
                        },
                      ),
                    ),
                  SizedBox(height: 20),

                  // Ticket Card
                  if (_canShowTicket) Obx(() => _TicketCard()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _TicketCard() {
    return Card(
      color: Colors.grey[100],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ticket Details",
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, color: AppColors.primary),
                SizedBox(width: 8),
                Text("From: ${_ticketController.locationFrom.value}"),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on, color: AppColors.primary),
                SizedBox(width: 8),
                Text("To: ${_ticketController.locationTo.value}"),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.directions_bus, color: AppColors.primary),
                SizedBox(width: 8),
                Text("Plate: ${_ticketController.plateNumber.value}"),
              ],
            ),
            Row(children: [
              Icon(Icons.arrow_circle_up, color: AppColors.primary),
              SizedBox(width: 8),
              Text("Level: ${_ticketController.level.value}"),
            ],),
            Row(
              children:[
                Icon(Icons.code, color: AppColors.primary),
                SizedBox(width: 8),
                Text("Region: ${_ticketController.region.value}"),
              ],
            ),
            Row(children: [
              Icon(Icons.people, color: AppColors.primary),
              SizedBox(width: 8),
              Text("Association: ${_ticketController.associations.value}"),
            ],),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.event_seat, color: AppColors.primary),
                SizedBox(width: 8),
                Text("Seats: ${_ticketController.seatNo.value}"),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.straighten, color: AppColors.primary),
                SizedBox(width: 8),
                Text("Distance: ${_ticketController.km.value}"),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.attach_money, color: AppColors.primary),
                SizedBox(width: 8),
                Text("Tariff: ${_ticketController.tariff.value}"),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.miscellaneous_services, color: AppColors.primary),
                SizedBox(width: 8),
                Text("Service Charge: ${_ticketController.serviceCharge.value}"),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.payments, color: AppColors.primary),
                SizedBox(width: 8),
                Text("Total Payment: ${_ticketController.totalPayment.value}"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

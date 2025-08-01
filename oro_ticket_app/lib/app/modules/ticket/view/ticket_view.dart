import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:oro_ticket_app/app/modules/home/controllers/home_controller.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/core/constants/dimensions.dart';
import 'package:oro_ticket_app/core/constants/typography.dart';
import 'package:oro_ticket_app/data/locals/models/trip_model.dart';
import 'package:oro_ticket_app/data/locals/models/vehicle_model.dart';
import 'package:oro_ticket_app/data/locals/models/departure_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/models/arrival_terminal_model.dart';
import 'package:oro_ticket_app/widgets/app_scafold.dart';
import '../controller/ticket_controller.dart';
import 'package:ethiopian_datetime/ethiopian_datetime.dart';
import 'package:oro_ticket_app/data/locals/models/service_charge_model.dart';

import 'package:oro_ticket_app/data/locals/hive_boxes.dart';

class TicketView extends StatefulWidget {
  @override
  State<TicketView> createState() => _TicketViewState();
}

class _TicketViewState extends State<TicketView> {
  final _ticketController = Get.put(TicketController());
  final homeController = Get.put(HomeController());

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
    final terminalBox =
        Hive.box<DepartureTerminalModel>('departureTerminalsBox');
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
      plateInput.isNotEmpty &&
      selectedDeparture != null &&
      selectedArrival != null;

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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text("Oromia Transport Agency"),
                  SizedBox(height: 20),

                  // Departure Terminal (read-only)
                  TextFormField(
                    readOnly: true,
                    initialValue: selectedDeparture,
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
                    isExpanded: true,
                    hint: Text('Select destination'),
                    onChanged: (val) {
                      setState(() {
                        selectedArrival = val;
                      });
                      if (val != null) {
                        _ticketController.locationTo.value = val.name;
                        _ticketController.km.value =
                            "${val.distance.toStringAsFixed(1)} km";
                        _ticketController.tariff.value =
                            "${val.tariff.toStringAsFixed(2)} ETB";
                        _ticketController.calculateCharges(val.tariff);

                        _ticketController.arrivalTerminalId.value = val.id;
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
                            subtitle: Text(
                                '${vehicle.plateRegion} • ${vehicle.fleetType}'),
                            onTap: () {
                              plateController.text = vehicle.plateNumber;
                              plateInput = vehicle.plateNumber;
                              suggestions.clear();

                              _ticketController.plateNumber.value =
                                  vehicle.plateNumber;
                              _ticketController.level.value =
                                  vehicle.vehicleLevel;
                              _ticketController.seatNo.value =
                                  vehicle.seatCapacity.toString();
                              _ticketController.level.value =
                                  vehicle.vehicleLevel;
                              _ticketController.associations.value =
                                  vehicle.associationName;
                              _ticketController.vehicleId.value = vehicle.id;
                              _ticketController.locationFrom.value =
                                  vehicle.assignedTerminalId!;
                              _ticketController.region.value =
                                  vehicle.plateRegion;

                              _ticketController.fleetType.value =
                                  vehicle.fleetType;
                              // Set the date and time
                              final now = DateTime.now();
                              final ethDate = now.convertToEthiopian();

                              _ticketController.dateTime.value =
                                  "${TicketController.oromoWeekdays[now.weekday]} - "
                                  "${ethDate.year}/${ethDate.month.toString().padLeft(2, '0')}/${ethDate.day.toString().padLeft(2, '0')} "
                                  "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

                              setState(() {}); // Refresh suggestion UI
                            },
                          );
                        },
                      ),
                    ),
                  SizedBox(height: 20),

                  // Ticket Card
                  if (_canShowTicket) Obx(() => _redesignedTicketCard()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _redesignedTicketCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Ticket Deatils", style: AppTextStyles.buttonMediumB),
            SizedBox(height: 5),
            Text("Oromia Transport Agency", style: AppTextStyles.heading3),
            SizedBox(height: 10),
            Text(homeController.companyName.value,
                style: AppTextStyles.buttonMediumB
                    .copyWith(color: Colors.grey, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.directions_bus, color: AppColors.primary),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Plate Number',
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.grey, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Text(_ticketController.region.value,
                            style: AppTextStyles.body2
                                .copyWith(fontWeight: FontWeight.bold)),
                        Text(_ticketController.plateNumber.value,
                            style: AppTextStyles.body2
                                .copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.business, color: AppColors.primary),
                    ),
                    SizedBox(width: 12),
                    Text('Association',
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(_ticketController.associations.value,
                    style: AppTextStyles.body2
                        .copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            Divider(height: 30),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    CircleAvatar(
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        child:
                            Icon(Icons.location_pin, color: AppColors.primary)),
                    SizedBox(width: 12),
                    _locationColumn(_ticketController.locationFrom.value, ""),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        child:
                            Icon(Icons.location_pin, color: AppColors.primary)),
                    SizedBox(width: 12),
                    _locationColumn(_ticketController.locationTo.value, ""),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      _ticketController.dateTime.value,
                      style: AppTextStyles.caption.copyWith(
                          color: Colors.grey, fontWeight: FontWeight.bold),
                    )
                  ],
                )
              ],
            ),
            Divider(height: 30),
            Row(
              children: [
                _infoTag(
                    Icons.event_seat, "${_ticketController.seatNo.value} Seat"),
                SizedBox(width: 12),
                _infoTag(Icons.grade, _ticketController.level.value),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              children: [
                _infoTag(Icons.straighten, _ticketController.km.value),
                SizedBox(width: 12),
                _infoTag(Icons.monetization_on, _ticketController.tariff.value),
              ],
            ),
            Divider(
              height: 30,
            ),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Service Charge',
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.grey, fontWeight: FontWeight.bold)),
                    Text(
                      _ticketController.serviceCharge.value,
                      style: AppTextStyles.body2
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(width: AppDimensions.horizontalSpacingLarge),
                Column(
                  children: [
                    Text("Total Payment",
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.grey, fontWeight: FontWeight.bold)),
                    Text(
                      _ticketController.totalPayment.value,
                      style: AppTextStyles.body2
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Agent Name: ${homeController.user.value?.fullName}",
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.grey, fontWeight: FontWeight.bold)),
                    SizedBox(
                      height: 10,
                    ),
                    Text("Free Call Service: 8556",
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.grey, fontWeight: FontWeight.bold))
                  ],
                ),
              ],
            ),
            SizedBox(
              height: AppDimensions.horizontalSpacingSmall,
            ),
            ElevatedButton(
              onPressed: () async {
                final tripBox = Hive.box<TripModel>(HiveBoxes.tripBox);
                final serviceChargeBox =
                    Hive.box<ServiceChargeModel>(HiveBoxes.serviceChargeBox);

                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);

                // Parse double values safely
                double parseSafe(String value) =>
                    double.tryParse(value.split(' ').first) ?? 0.0;

                final trip = TripModel(
                  vehicleId: _ticketController.vehicleId.value,
                  departureTerminalId: _ticketController.locationFrom.value,
                  arrivalTerminalId: _ticketController.arrivalTerminalId.value,
                  dateAndTime: now,
                  km: parseSafe(_ticketController.km.value),
                  tariff: parseSafe(_ticketController.tariff.value),
                  serviceCharge:
                      parseSafe(_ticketController.serviceCharge.value),
                  totalPaid: parseSafe(_ticketController.totalPayment.value),
                  employeeId: homeController.user.value!.id,
                  companyId: homeController.companyId.value,
                );

                // ✅ Save Trip
                await tripBox.add(trip);

                // ✅ Handle Service Charge (per day per terminal per employee)
                final existingEntry =
                    serviceChargeBox.values.firstWhereOrNull((entry) {
                  final entryDate = DateTime(entry.dateTime.year,
                      entry.dateTime.month, entry.dateTime.day);
                  return entry.departureTerminal == trip.departureTerminalId &&
                      entry.employeeName == trip.employeeId &&
                      entryDate == today;
                });

                if (existingEntry != null) {
                  existingEntry.serviceChargeAmount += trip.serviceCharge;
                  await existingEntry.save();
                } else {
                  final newCharge = ServiceChargeModel(
                    departureTerminal: trip.departureTerminalId,
                    dateTime: now,
                    serviceChargeAmount: trip.serviceCharge,
                    employeeName: trip.employeeId,
                    companyId: trip.companyId,
                  );
                  await serviceChargeBox.add(newCharge);
                  homeController.loadServiceChargeAndDate();
                }

                Get.snackbar(
                  "Saved",
                  "Ticket & Service Charge updated successfully",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green.withOpacity(0.8),
                  colorText: Colors.white,
                );
              },

              // Add confirmation logic here
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              //free call service
              child: Text("Print", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  Widget _locationColumn(String label, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.caption2
                .copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text(time,
            style: AppTextStyles.caption
                .copyWith(color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _infoTag(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

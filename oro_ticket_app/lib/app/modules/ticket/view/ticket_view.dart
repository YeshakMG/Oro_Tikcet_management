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
import 'package:oro_ticket_app/widgets/ticket_widget.dart';
import 'package:pdf/pdf.dart';
import '../controller/ticket_controller.dart';
import 'package:ethiopian_datetime/ethiopian_datetime.dart';
import 'package:oro_ticket_app/data/locals/models/service_charge_model.dart';
import 'package:oro_ticket_app/data/locals/hive_boxes.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:hive/hive.dart';
import 'package:oro_ticket_app/data/locals/models/commission_rule_model.dart';
import 'package:oro_ticket_app/data/locals/models/trip_model.dart';

import 'package:oro_ticket_app/app/modules/utils/ticket_printer.dart';






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
    final terminalBox = Hive.box<DepartureTerminalModel>('departureTerminalsBox');
    final terminal = terminalBox.values.firstOrNull;

    if (terminal != null) {
      setState(() {
        selectedDeparture = terminal.name;
        _ticketController.locationFrom.value = terminal.name;
        _ticketController.departureTerminalId.value = terminal.id; // ✅ set correct ID
        _ticketController.selectedDepartureTerminal.value = terminal; // ✅ store full model if needed
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
                              
                              _ticketController.region.value =
                                  vehicle.plateRegion;
                              // _ticketController.departureTerminalId.value = 
                              //     _ticketController.locationFrom.value;
                                  

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
            Text("Ticket Details", style: AppTextStyles.buttonMediumB),
            SizedBox(height: 5),
            Text("Oromia Transport Agency", style: AppTextStyles.heading3),
            SizedBox(height: 10),
            Text(homeController.companyName.value,
                style: AppTextStyles.buttonMediumB
                    .copyWith(color: Colors.grey, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Phone: 011-1234567",
                style: AppTextStyles.caption
                    .copyWith(color: Colors.grey, fontWeight: FontWeight.bold)),
            
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
                            color: Colors.grey, fontWeight: FontWeight.bold)),
                    Text("Terminal phone: 011-1234567",
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.grey, fontWeight: FontWeight.bold)),
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
                final serviceChargeBox = Hive.box<ServiceChargeModel>(HiveBoxes.serviceChargeBox);

                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);

                double parseSafe(String value) =>
                    double.tryParse(value.split(' ').first) ?? 0.0;

                // Seat count from controller (string to int)
                final int seatCount = int.tryParse(_ticketController.seatNo.value) ?? 1;

                // Multiply service charge by number of selected seats
                final double totalServiceCharge =
                    parseSafe(_ticketController.serviceCharge.value) * seatCount;

                final trip = TripModel(
                  vehicleId: _ticketController.vehicleId.value,
                  departureTerminalId: _ticketController.departureTerminalId.value,
                  arrivalTerminalId: _ticketController.arrivalTerminalId.value,
                  dateAndTime: now,
                  km: parseSafe(_ticketController.km.value),
                  tariff: parseSafe(_ticketController.tariff.value),
                  serviceCharge: totalServiceCharge,
                  totalPaid: parseSafe(_ticketController.totalPayment.value),
                  employeeId: homeController.user.value!.id,
                  companyId: homeController.companyId.value,
                  departureName: selectedDeparture.toString(),
                  arrivalName: _ticketController.locationTo.value,
                );

                // Debug TripModel print
                print("🚌 TripModel Debug Info:");
                print("Vehicle ID: ${trip.vehicleId}");
                print("From: ${trip.departureTerminalId}, To: ${trip.arrivalTerminalId}");
                print("KM: ${trip.km}, Tariff: ${trip.tariff}, Charge: ${trip.serviceCharge}");
                print("Total Paid: ${trip.totalPaid}, Employee: ${trip.employeeId}, Company: ${trip.companyId}");
                print("Date: ${trip.dateAndTime}");

                await tripBox.add(trip);

                // Check if a charge already exists for today, terminal, and employee
                final existingEntry = serviceChargeBox.values.firstWhereOrNull((entry) {
                  final entryDate = DateTime(entry.dateTime.year, entry.dateTime.month, entry.dateTime.day);
                  return entry.departureTerminal == trip.departureTerminalId &&
                      entry.employeeName == trip.employeeId &&
                      entryDate == today;
                });

                if (existingEntry != null) {
                  // Add new service charge to existing
                  existingEntry.serviceChargeAmount += totalServiceCharge;
                  await existingEntry.save();

                  // Debug updated ServiceChargeModel
                  print("💵 Updated ServiceChargeModel:");
                  print("Terminal: ${existingEntry.departureTerminal}, Employee: ${existingEntry.employeeName}");
                  print("New Charge: ${existingEntry.serviceChargeAmount}, Date: ${existingEntry.dateTime}");
                } else {
                  // Create new entry
                  final newCharge = ServiceChargeModel(
                    departureTerminal: trip.departureTerminalId,
                    dateTime: now,
                    serviceChargeAmount: totalServiceCharge,
                    employeeName: trip.employeeId,
                    companyId: trip.companyId,
                  );

                  await serviceChargeBox.add(newCharge);

                  // Debug new ServiceChargeModel
                  print("💰 New ServiceChargeModel:");
                  print("Terminal: ${newCharge.departureTerminal}, Employee: ${newCharge.employeeName}");
                  print("Charge: ${newCharge.serviceChargeAmount}, Date: ${newCharge.dateTime}");
                }

                // === Printing logic ===
                // final printer = TicketPrinter();

                final ticketText = '''
            Oromia Transport Agency
            -------------------------------
              Company: Malkaa Technology
              Phone: 011-123-4567
            Plate: ${_ticketController.region.value} ${_ticketController.plateNumber.value}
            From: ${_ticketController.locationFrom.value}
            To: ${_ticketController.locationTo.value}
            Date: ${_ticketController.dateTime.value}
            Seat No: ${_ticketController.seatNo.value}
            Level: ${_ticketController.level.value}
            Km: ${_ticketController.km.value}
            Tariff: ${_ticketController.tariff.value}
            Service Charge: ${_ticketController.serviceCharge.value}
            Total Payment: ${_ticketController.totalPayment.value}
            Agent: ${homeController.user.value?.fullName}
            -------------------------------
            Free-call: 8556
            Phone: 011-123-4567

            ''';

                final copies = int.tryParse(_ticketController.seatNo.value) ?? 1;

                // await printer.connectAndPrint(text: ticketText, copies: copies);

                // Success Feedback Snackbar
                Get.snackbar(
                  "Saved",
                  "Ticket & Service Charge updated and printed successfully",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green.withOpacity(0.8),
                  colorText: Colors.white,
                );
              //   final savedTrip = tripBox.get(tripKey);
              //   if (savedTrip != null) {
              //     _printTicketWithQR(savedTrip, tripKey.toString());
              //   }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Print & Save"),
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

 /* void _printTicketWithQR(TripModel trip, String tripId) async {
    final ticketWidget = PrintableTicketWidget(
      tripId: tripId,
      plateNumber: _ticketController.plateNumber.value,
      region: _ticketController.region.value,
      association: _ticketController.associations.value,
      departure: trip.departureName,
      arrival: trip.arrivalName,
      level: _ticketController.level.value,
      seat: _ticketController.seatNo.value,
      distance: trip.km.toString(),
      tariff: trip.tariff.toString(),
      serviceCharge: trip.serviceCharge.toString(),
      totalPaid: trip.totalPaid.toString(),
      agent: homeController.user.value?.fullName ?? 'Unknown Agent',
      dateTime: trip.dateAndTime.toString(), // You may format this
    );

    // You can preview the ticket before printing if needed
    await Get.to(() => Scaffold(
          appBar: AppBar(title: Text("Ticket Preview")),
          body: Center(child: ticketWidget),
        ));
  // await Printing.layoutPdf(
  //   onLayout: (PdfPageFormat format) async => pdf.save(),
  // );
    // OR if using a print package, you can convert `ticketWidget` to image/pdf and print
  }
*/
}

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
import 'dart:convert';
import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:hive/hive.dart';
import 'package:oro_ticket_app/data/locals/models/commission_rule_model.dart';
import 'package:oro_ticket_app/data/locals/models/trip_model.dart';
import 'package:intl/intl.dart';
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
    final terminalBox =
        Hive.box<DepartureTerminalModel>('departureTerminalsBox');
    final terminal = terminalBox.values.firstOrNull;

    if (terminal != null) {
      setState(() {
        selectedDeparture = terminal.name;
        _ticketController.locationFrom.value = terminal.name;
        _ticketController.departureTerminalId.value =
            terminal.id; // ✅ set correct ID
        _ticketController.selectedDepartureTerminal.value =
            terminal; // ✅ store full model if needed
      });
    }
  }

  void _onPlateInputChanged(String input) {
    final vehicleBox = Hive.box<VehicleModel>('vehiclesBox');

    final filtered = vehicleBox.values
        .where((v) =>
            v.plateNumber.toLowerCase().contains(input.toLowerCase()) &&
            v.status.toLowerCase() == 'active')
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
    final size = MediaQuery.of(context).size;
    final paddingHorizontal = size.width * 0.04; // 4% of screen width
    final paddingVertical = size.height * 0.02; // 2% of screen height

    return AppScaffold(
      title: "Ticket",
      userName: "Employee Name",
      currentBottomNavIndex: 1,
      showBottomNavBar: true,
      actions: [
        const Icon(Icons.more_horiz, color: Colors.white),
        SizedBox(width: paddingHorizontal),
      ],
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(paddingHorizontal),
          child: Column(
            children: [
              Text("Oromia Transport Agency"),
              SizedBox(height: paddingVertical * 2.5),

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
              SizedBox(height: paddingVertical * 1.25),

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
              SizedBox(height: paddingVertical * 1.25),

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
                  margin: EdgeInsets.only(top: paddingVertical),
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
                          _ticketController.level.value = vehicle.vehicleLevel;
                          _ticketController.seatNo.value =
                              vehicle.seatCapacity.toString();
                          _ticketController.level.value = vehicle.vehicleLevel;
                          _ticketController.associations.value =
                              vehicle.associationName;
                          _ticketController.vehicleId.value = vehicle.id;

                          _ticketController.region.value = vehicle.plateRegion;
                          // _ticketController.departureTerminalId.value =
                          //     _ticketController.locationFrom.value;

                          _ticketController.fleetType.value = vehicle.fleetType;
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
              SizedBox(height: paddingVertical * 2.5),

              // Ticket Card
              if (_canShowTicket) Obx(() => _redesignedTicketCard(size, paddingHorizontal, paddingVertical)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _redesignedTicketCard(Size size, double paddingHorizontal, double paddingVertical) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Text("Ticket Details", style: AppTextStyles.buttonMediumB),
          SizedBox(height: 5),
          Text("Oromia Transport Agency", style: AppTextStyles.heading3),
          SizedBox(height: 5),
          Text(homeController.companyName.value,
              style: AppTextStyles.buttonMediumB
                  .copyWith(color: Colors.grey, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Text("Phone: 011-1234567",
              style: AppTextStyles.caption
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
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(Icons.business, color: AppColors.primary),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Association',
                      style: AppTextStyles.caption.copyWith(
                          color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text(_ticketController.associations.value,
                      style: AppTextStyles.body2
                          .copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          Divider(
            height: 30,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.my_location, color: AppColors.primary)),
                  SizedBox(width: 12),
                  _locationColumn(_ticketController.locationFrom.value),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child:
                          Icon(Icons.location_pin, color: AppColors.primary)),
                  SizedBox(width: 12),
                  _locationColumn(_ticketController.locationTo.value),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Text(_ticketController.dateTime.value,
                      style: AppTextStyles.caption.copyWith(
                          color: Colors.black, fontWeight: FontWeight.bold))
                ],
              )
            ],
          ),
          Divider(height: 30),
          Row(
            children: [
              _infoTag(
                  Icons.event_seat, "${_ticketController.seatNo.value} Seat"),
              SizedBox(width: 50),
              _infoTag(Icons.grade, _ticketController.level.value),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            children: [
              _infoTag(Icons.straighten, _ticketController.km.value),
              SizedBox(width: 35),
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
              SizedBox(width: 50),
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
                  SizedBox(
                    height: 10,
                  ),
                  Text("Terminal phone: 011-1234567",
                      style: AppTextStyles.caption.copyWith(
                          color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          SizedBox(
            height: AppDimensions.horizontalSpacingMedium,
          ),
          ElevatedButton(
            onPressed: () async {
              // Show confirmation dialog - prevent dismissing by tapping outside
              final result = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  title: Text("Confirm Action", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  content: Text("Do you want to proceed with printing and saving?"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      child: Text("Cancel", style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: Text("Proceed", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );

              // Handle result - proceed only if result is explicitly true
              if (result != true) {
                return; // User cancelled or dismissed, do nothing
              }

              // User clicked Proceed - execute save and print logic

              // Show loading dialog
              Get.dialog(
                PopScope(
                  canPop: false,
                  child: AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(width: 20),
                        Text("Processing...", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                barrierDismissible: false,
              );

              // User clicked Proceed - execute save and print logic
              try {
                final tripBox = Hive.box<TripModel>(HiveBoxes.tripBox);
                final serviceChargeBox =
                    Hive.box<ServiceChargeModel>(HiveBoxes.serviceChargeBox);

                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);

                double parseSafe(String value) =>
                    double.tryParse(value.split(' ').first) ?? 0.0;

                // Seat count from controller (string to int)
                final int seatCount =
                    int.tryParse(_ticketController.seatNo.value) ?? 1;

                // Multiply service charge by number of selected seats
                final double totalServiceCharge =
                    parseSafe(_ticketController.serviceCharge.value) * seatCount;

                final trip = TripModel(
                  vehicleId: _ticketController.vehicleId.value,
                  departureTerminalId:
                      _ticketController.departureTerminalId.value,
                  arrivalTerminalId: _ticketController.arrivalTerminalId.value,
                  dateAndTime: now,
                  km: parseSafe(_ticketController.km.value),
                  tariff: parseSafe(_ticketController.tariff.value),
                  serviceCharge: parseSafe(_ticketController.serviceCharge.value),
                  totalPaid: parseSafe(_ticketController.totalPayment.value),
                  employeeId: homeController.user.value!.id,
                  companyId: homeController.companyId.value,
                  departureName: selectedDeparture.toString(),
                  arrivalName: _ticketController.locationTo.value,
                );

                // Debug TripModel payload
                print("===========================================");
                print("🚌 TRIP PAYLOAD:");
                print("===========================================");
                print(jsonEncode(trip.toJson()));
                print("===========================================");

                final tripKey = await tripBox.add(trip);

                // Check if a charge already exists for today, terminal, and employee
                final existingEntry =
                    serviceChargeBox.values.firstWhereOrNull((entry) {
                  final entryDate = DateTime(entry.dateTime.year,
                      entry.dateTime.month, entry.dateTime.day);
                  
                  return entry.departureTerminal == trip.departureTerminalId &&
                      entry.employeeId == trip.employeeId &&
                      entryDate == today;
                  
                });

                if (existingEntry != null) {
                  // Add new service charge to existing
                  existingEntry.serviceChargeAmount += totalServiceCharge;
                  await existingEntry.save();

                  // Debug updated ServiceChargeModel payload
                  print("===========================================");
                  print("💵 SERVICE CHARGE PAYLOAD (UPDATED):");
                  print("===========================================");
                  print(jsonEncode(existingEntry.toJson()));
                  print("===========================================");
                } else {
                  // Create new entry
                  final newCharge = ServiceChargeModel(
                    departureTerminal: trip.departureTerminalId,
                    dateTime: now,
                    serviceChargeAmount: totalServiceCharge,
                    employeeName: homeController.user.value!.fullName,
                    companyId: trip.companyId,
                    employeeId: trip.employeeId,
                  );

                  await serviceChargeBox.add(newCharge);

                  // Debug new ServiceChargeModel payload
                  print("===========================================");
                  print("💰 SERVICE CHARGE PAYLOAD (NEW):");
                  print("===========================================");
                  print(jsonEncode(newCharge.toJson()));
                  print("===========================================");
                }
                final ticketText = formatTicketText(
                    companyName: homeController.companyName.value,
                    companyPhoneNo: homeController.companyPhoneNo.value,
                    region: _ticketController.region.value,
                    plateNumber: _ticketController.plateNumber.value,
                    from: trip.departureName,
                    to: trip.arrivalName,
                    dateTime: trip.dateAndTime,
                    seatNo: _ticketController.seatNo.value,
                    association: _ticketController.associations.value,
                    level: _ticketController.level.value,
                    km: trip.km,
                    tariff: trip.tariff,
                    serviceCharge:
                        parseSafe(_ticketController.serviceCharge.value),
                    totalPayment: trip.totalPaid,
                    agent: homeController.user.value!.fullName);
                final qrcodeData =
                    '${trip.departureName}\n${trip.arrivalName}\n${trip.dateAndTime}\n${_ticketController.region}${_ticketController.plateNumber.value}';

                final printer = TicketPrinter();

                final exitTicket = formatExitTicketText(
                    companyName: homeController.companyName.value,
                    companyPhoneNo: homeController.companyPhoneNo.value,
                    region: _ticketController.region.value,
                    plateNumber: _ticketController.plateNumber.value,
                    from: trip.departureName,
                    to: trip.arrivalName,
                    dateTime: trip.dateAndTime,
                    seatCapacity: _ticketController.seatNo.value,
                    association: _ticketController.associations.value,
                    level: _ticketController.level.value,
                    agent: homeController.user.value!.fullName);
                // Get seat count for number of copies to print
                final copies = int.tryParse(_ticketController.seatNo.value) ?? 1;
                debugPrint('DEBUG: Printing $copies ticket(s) for seat capacity: ${_ticketController.seatNo.value}');

                await printer.connectAndPrint(
                    text: ticketText,
                    qrCodeData: qrcodeData,
                    copies: copies,
                    exitText: exitTicket);

                // Close loading dialog
                Get.back();

                // Show success message
                Get.dialog(
                  AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 48),
                        SizedBox(height: 16),
                        Text("Successfully ordered tickets!", 
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Get.back(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: Text("OK"),
                      ),
                    ],
                  ),
                );
              } catch (e) {
                // Close loading dialog on error
                Get.back();
                // Show error message
                Get.snackbar(
                  "Error",
                  "Failed to process ticket: $e",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red.withValues(alpha: 0.8),
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              "Print & Save",
              style: AppTextStyles.button,
            ),
          )
        ],
      ),
    );
  }

  Widget _locationColumn(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label,
            style: AppTextStyles.caption2
                .copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
        SizedBox(
          height: 5,
        )
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

String formatTicketText({
  required String companyName,
  required String companyPhoneNo,
  required String region,
  required String plateNumber,
  required String from,
  required String to,
  required DateTime dateTime,
  required String seatNo,
  required String association,
  required String level,
  required double km,
  required double tariff,
  required double serviceCharge,
  required double totalPayment,
  required String agent,
}) {
  const lineWidth = 30;
  String line(String left, String right) {
    final available = lineWidth - left.length;
    return left + right.padLeft(available);
  }

  final ethDate = dateTime.convertToEthiopian();
  final dateStr = "${ethDate.day}-${ethDate.month}-${ethDate.year}";
  final timeStr =
      "${ethDate.hour.toString().padLeft(2, '0')}:${ethDate.minute.toString().padLeft(2, '0')}";
  return '''
Oromia Transport Agency
${'=' * lineWidth}
${line("Company:", companyName)}
${line("Tel:", companyPhoneNo)}
${line("Date:", "$dateStr $timeStr")}
${'-' * lineWidth}
${line("From:", from)}
${line("To:", to)}
${line("Plate:", "$region$plateNumber")}
${line("Association:", association)}
${line("Seat Capacity:", seatNo)}
${line("Level:", level)}
${line("KM:", km.toStringAsFixed(2))}
${'-' * lineWidth}
${line("Tariff:", tariff.toStringAsFixed(2))}
${line("Service Charge:", serviceCharge.toStringAsFixed(2))}
${line("TOTAL:", totalPayment.toStringAsFixed(2))}
${'-' * lineWidth}
${line("Agent:", agent)}
${line("Free-call:", "8556")}
${line("Terminal Tel:", "011-123-4567")}''';
}

String formatExitTicketText({
  required String companyName,
  required String companyPhoneNo,
  required String region,
  required String plateNumber,
  required String from,
  required String to,
  required DateTime dateTime,
  required String seatCapacity, // total seat capacity of the vehicle
  required String association,
  required String level,
  required String agent,
}) {
  const lineWidth = 30;
  String line(String left, String right) {
    final available = lineWidth - left.length;
    return left + right.padLeft(available);
  }

  final ethDate = dateTime.convertToEthiopian();
  final dateStr = "${ethDate.day}-${ethDate.month}-${ethDate.year}";
  final timeStr =
      "${ethDate.hour.toString().padLeft(2, '0')}:${ethDate.minute.toString().padLeft(2, '0')}";

  return '''
${line("Company:", companyName)}
${line("Tel:", companyPhoneNo)}
${line("Date:", "$dateStr $timeStr")}
${'-' * lineWidth}
${line("From:", from)}
${line("To:", to)}
${line("Plate:", "$region$plateNumber")}
${line("Association:", association)}
${line("Seat Capacity:", seatCapacity)}
${line("Level:", level)}
${'-' * lineWidth}
${line("Agent:", agent)}
''';
}

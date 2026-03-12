import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:ethiopian_datetime/ethiopian_datetime.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/core/constants/typography.dart';
import 'package:oro_ticket_app/widgets/app_scafold.dart';
import 'package:oro_ticket_app/data/locals/backup_service.dart';

import '../controller/sync_controller.dart';
import 'package:oro_ticket_app/data/locals/models/trip_model.dart';
import 'package:oro_ticket_app/data/locals/models/vehicle_model.dart';
import 'package:oro_ticket_app/data/locals/models/departure_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/models/arrival_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/hive_boxes.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class SyncView extends StatefulWidget {
  const SyncView({super.key});

  @override
  State<SyncView> createState() => _SyncViewState();
}

class _SyncViewState extends State<SyncView> {
  final SyncController controller = Get.put(SyncController());
  Map<String, int> _unsyncedCounts = {'trips': 0, 'serviceCharges': 0, 'total': 0};

  @override
  void initState() {
    super.initState();
    _loadUnsyncedCounts();
  }

  Future<void> _loadUnsyncedCounts() async {
    final counts = await BackupService.getUnsyncedCount();
    if (mounted) {
      setState(() {
        _unsyncedCounts = counts;
      });
    }
  }

  Future<void> _exportBackup() async {
    await BackupService.exportAndShare();
    await _loadUnsyncedCounts();
  }

  Future<void> _importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        // Show loading
        Get.dialog(
          const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Importing backup..."),
              ],
            ),
          ),
          barrierDismissible: false,
        );

        final file = File(result.files.single.path!);
        final jsonContent = await file.readAsString();

        final importedCount = await BackupService.importData(jsonContent);

        Get.back(); // Close loading

        await _loadUnsyncedCounts();

        Get.snackbar(
          "Success",
          "$importedCount records imported successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      // Close loading if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      Get.snackbar(
        "Error",
        "Failed to import backup: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final paddingHorizontal = size.width * 0.04; // 4% of screen width
    final paddingVertical = size.height * 0.02; // 2% of screen height

    return AppScaffold(
      title: "Sync Tickets",
      userName: '',
      actions: [
        // Backup/Export button
        IconButton(
          icon: const Icon(Icons.backup, color: Colors.white),
          onPressed: _exportBackup,
          tooltip: 'Export Backup',
        ),
        // Import button
        IconButton(
          icon: const Icon(Icons.restore, color: Colors.white),
          onPressed: _importBackup,
          tooltip: 'Import Backup',
        ),
        SizedBox(width: paddingHorizontal),
      ],
      body: Column(
        children: [
          _buildUnsyncedBanner(paddingHorizontal, paddingVertical),
          _buildTopBar(size, paddingHorizontal),
          Expanded(
            child: Obx(() {
              final tickets = controller.filteredTickets;
              if (tickets.isEmpty) {
                return const Center(child: Text("No matching tickets found."));
              }
              return RefreshIndicator(
                onRefresh: controller.refreshTickets,
                child: ListView.builder(
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    return _buildTicketCard(tickets[index], size, paddingHorizontal, paddingVertical);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsyncedBanner(double paddingHorizontal, double paddingVertical) {
    final hasUnsynced = _unsyncedCounts['total']! > 0;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(paddingHorizontal),
      color: hasUnsynced ? Colors.orange.shade100 : Colors.green.shade100,
      child: Row(
        children: [
          Icon(
            hasUnsynced ? Icons.warning : Icons.check_circle,
            color: hasUnsynced ? Colors.orange : Colors.green,
          ),
          SizedBox(width: paddingHorizontal),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasUnsynced 
                      ? "Unsynced Data (Backup Recommended)" 
                      : "All Data Synced",
                  style: AppTextStyles.buttonMediumB.copyWith(
                    color: hasUnsynced ? Colors.orange.shade800 : Colors.green.shade800,
                  ),
                ),
                Text(
                  "${_unsyncedCounts['trips']} trips, ${_unsyncedCounts['serviceCharges']} service charges",
                  style: AppTextStyles.caption.copyWith(
                    color: hasUnsynced ? Colors.orange.shade700 : Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          if (hasUnsynced)
            ElevatedButton.icon(
              onPressed: _exportBackup,
              icon: const Icon(Icons.backup, size: 18),
              label: const Text("Backup"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(Size size, double paddingHorizontal) {
    final spacing = size.width * 0.02; // 2% for spacing

    return Padding(
      padding: EdgeInsets.all(paddingHorizontal),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (val) => controller.searchQuery.value = val,
              decoration: InputDecoration(
                hintText: "Search by Plate No., Terminal, Association...",
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(TripModel trip, Size size, double paddingHorizontal, double paddingVertical) {
    final vehicleBox = Hive.box<VehicleModel>(HiveBoxes.vehiclesBox);
    final departureBox =
        Hive.box<DepartureTerminalModel>(HiveBoxes.departureTerminalsBox);
    final arrivalBox =
        Hive.box<ArrivalTerminalModel>(HiveBoxes.arrivalTerminalsBox);

    final vehicle = vehicleBox.values.firstWhere(
      (v) => v.id == trip.vehicleId,
      orElse: () => VehicleModel(
        id: "unknown",
        plateNumber: "unknown",
        plateRegion: "unknown",
        fleetType: "unknown",
        vehicleLevel: "Standard",
        associationName: "unknown",
        seatCapacity: 0,
        status: "unknown",
        arrivalTerminals: [],
        tariffs: [],
      ),
    );

    final departure = departureBox.values.firstWhere(
      (d) => d.id == trip.departureTerminalId,
      orElse: () => DepartureTerminalModel(
          id: "unknown", name: "Unknown", status: "active"),
    );

    final arrival = arrivalBox.values.firstWhere(
      (a) => a.id == trip.arrivalTerminalId,
      orElse: () => ArrivalTerminalModel(
          id: "unknown", name: "Unknown", tariff: 0.0, distance: 0.0),
    );

    final ethDate = trip.dateAndTime.convertToEthiopian();

    return Card(
      margin: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: paddingVertical),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade100, Colors.white],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(paddingHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section with plate and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Plate: ${vehicle.plateRegion}${vehicle.plateNumber}",
                    style: AppTextStyles.buttonMediumB,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: trip.isSynced
                          ? Colors.green.shade300
                          : Colors.red.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      trip.isSynced ? "Synced" : "Not Synced",
                      style: AppTextStyles.buttonSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Divider(color: Colors.grey.shade300, height: 20),

              // Route information
              Row(
                children: [
                  const Icon(Icons.place, size: 18, color: Colors.red),
                  SizedBox(width: size.width * 0.02),
                  Expanded(
                    child: Text(
                      "${departure.name} → ${arrival.name}",
                      style: AppTextStyles.buttonMediumB,
                    ),
                  ),
                ],
              ),
              SizedBox(height: paddingVertical),

              // Association information
              Row(
                children: [
                  const Icon(Icons.business, size: 18, color: Colors.blue),
                  SizedBox(width: size.width * 0.02),
                  Text(
                    vehicle.associationName,
                    style: AppTextStyles.buttonMediumB,
                  ),
                ],
              ),
              SizedBox(height: paddingVertical * 1.5),
              Row(
                children: [
                  const Icon(Icons.event_seat, size: 18, color: Colors.blue),
                  SizedBox(width: size.width * 0.02),
                  Text(
                    'Seat Number-${vehicle.seatCapacity.toString()}',
                    style: AppTextStyles.buttonMediumB,
                  ),
                ],
              ),
              SizedBox(height: paddingVertical * 1.5),
              // Pricing section
              Container(
                padding: EdgeInsets.all(paddingHorizontal),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPriceItem("Tariff", trip.tariff.toString()),
                    _buildPriceItem("Service", trip.serviceCharge.toString()),
                    _buildPriceItem("Total", trip.totalPaid.toString(),
                        isTotal: true),
                  ],
                ),
              ),
              SizedBox(height: paddingVertical * 1.5),

              // Date and time
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  SizedBox(width: size.width * 0.01),
                  Text(
                    "${ethDate.day}-${ethDate.month}-${ethDate.year} ${ethDate.hour}:${ethDate.minute.toString().padLeft(2, '0')}",
                    style: AppTextStyles.caption.copyWith(
                        color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceItem(String label, String value, {bool isTotal = false}) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.caption
              .copyWith(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.body2.copyWith(
            fontWeight: FontWeight.bold,
            color: isTotal ? Colors.green.shade800 : Colors.black,
          ),
        ),
      ],
    );
  }
}

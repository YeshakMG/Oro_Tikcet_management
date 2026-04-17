import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:ethiopian_datetime/ethiopian_datetime.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/core/constants/typography.dart';
import 'package:oro_ticket_app/widgets/app_scafold.dart';
import 'package:oro_ticket_app/app/modules/home/controllers/home_controller.dart';

import '../controller/sync_controller.dart';
import 'package:oro_ticket_app/data/locals/models/trip_model.dart';
import 'package:oro_ticket_app/data/locals/models/vehicle_model.dart';
import 'package:oro_ticket_app/data/locals/models/departure_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/models/arrival_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/hive_boxes.dart';

class SyncView extends StatefulWidget {
  const SyncView({super.key});

  @override
  State<SyncView> createState() => _SyncViewState();
}

class _SyncViewState extends State<SyncView> {
  final SyncController controller = Get.put(SyncController());
  final HomeController homeController = Get.find<HomeController>();
  String _syncMessage = '';
  String _syncMessageType = ''; // 'success', 'error', 'warning', 'info'
  double _paddingHorizontal = 16;
  double _paddingVertical = 16;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _syncToServer() async {
    // Show loading indicator
    Get.snackbar(
      'Syncing', 
      'Uploading data to server...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      showProgressIndicator: true,
      margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
    );
    
    // Check network connectivity first
    final isConnected = await homeController.checkConnectivity();
    
    if (!isConnected) {
      setState(() {
        _syncMessage = 'No Internet Connection. Please check your network and try again.';
        _syncMessageType = 'warning';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          'No Internet Connection',
          'Please check your network and try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        );
      });
      return;
    }
    
    // Sync trips only
    final tripsResult = await homeController.syncTrips();
    
    // Show result
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (tripsResult > 0) {
        setState(() {
          _syncMessage = '$tripsResult trip(s) uploaded successfully!';
          _syncMessageType = 'success';
        });
        Get.snackbar(
          'Sync Success',
          '$tripsResult trip(s) uploaded successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        );
      } else if (tripsResult == 0) {
        setState(() {
          _syncMessage = 'No trips to sync. All trips have already been synced.';
          _syncMessageType = 'warning';
        });
        Get.snackbar(
          'No Trips to Sync',
          'All trips have already been synced.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        );
      } else {
        setState(() {
          _syncMessage = 'Failed to upload trips. Please try again.';
          _syncMessageType = 'error';
        });
        Get.snackbar(
          'Sync Failed',
          'Failed to upload trips. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        );
      }
    });
    
    // Refresh after sync
    controller.refreshTickets();
  }

  Widget _buildSyncMessage() {
    if (_syncMessage.isEmpty) return const SizedBox.shrink();
    
    Color backgroundColor;
    Color textColor;
    IconData icon;
    
    switch (_syncMessageType) {
      case 'success':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle;
        break;
      case 'error':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        icon = Icons.error;
        break;
      case 'warning':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        icon = Icons.warning;
        break;
      case 'info':
      default:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        icon = Icons.info;
        break;
    }
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_paddingHorizontal),
      margin: EdgeInsets.symmetric(horizontal: _paddingHorizontal, vertical: _paddingVertical),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor),
          SizedBox(width: _paddingHorizontal),
          Expanded(
            child: Text(
              _syncMessage,
              style: AppTextStyles.body2.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _paddingHorizontal = size.width * 0.04;
    _paddingVertical = size.height * 0.02;

    return AppScaffold(
      title: "Trips",
      userName: '',
      actions: [
        SizedBox(width: _paddingHorizontal),
      ],
      body: Column(
        children: [
          _buildSyncButton(),
          _buildSyncMessage(),
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
                    return _buildTicketCard(tickets[index], size, _paddingHorizontal, _paddingVertical);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _paddingHorizontal, vertical: _paddingVertical),
      child: ElevatedButton.icon(
        onPressed: _syncToServer,
        icon: const Icon(Icons.cloud_upload, size: 20),
        label: const Text('Sync Trips'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: AppTextStyles.body2,
        ),
      ),
    );
  }

  Widget _buildUnsyncedBanner(double paddingHorizontal, double paddingVertical) {
    return const SizedBox.shrink();
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

import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:oro_ticket_app/data/locals/models/trip_model.dart';
import 'package:oro_ticket_app/data/locals/models/vehicle_model.dart';
import 'package:oro_ticket_app/data/locals/models/departure_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/models/arrival_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/hive_boxes.dart';
import 'package:intl/intl.dart';

class LocalReportController extends GetxController {
  RxList<Map<String, String>> allReports = <Map<String, String>>[].obs;
  RxList<Map<String, String>> filteredReports = <Map<String, String>>[].obs;
  RxString selectedStatus = ''.obs;
  RxBool sortAsc = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadTripsFromHive();
  }

  void loadTripsFromHive() async {
    final tripBox = await Hive.openBox<TripModel>('trip');
    
    // Open other boxes needed for related data
    final vehicleBox = await Hive.openBox('vehicles');
    final departureBox = await Hive.openBox('departureTerminals');
    final arrivalBox = await Hive.openBox('arrivalTerminals');
    
    final List<Map<String, String>> loaded = tripBox.values.map((trip) {
      // Get related data from other boxes if needed
      // For now, use safe defaults to fix the immediate errors
      
      return {
        'tripId': trip.key?.toString() ?? 'Unknown',
        'departure': _getDepartureName(departureBox, trip.departureTerminalId),
        'destination': _getArrivalName(arrivalBox, trip.arrivalTerminalId),
        'plate': _getPlateNumber(vehicleBox, trip.vehicleId),
        'date': DateFormat('yyyy-MM-dd').format(trip.dateAndTime),
        'time': DateFormat('hh:mm a').format(trip.dateAndTime),
        'status': 'Completed' // or use trip.status if you store it
      };
    }).toList();

    allReports.assignAll(loaded);
    filteredReports.assignAll(loaded);
  }

  void searchReports(String query) {
    if (query.isEmpty) {
      filteredReports.assignAll(allReports);
    } else {
      filteredReports.assignAll(allReports.where((report) =>
        report['tripId']!.contains(query) ||
        report['departure']!.toLowerCase().contains(query.toLowerCase()) ||
        report['plate']!.toLowerCase().contains(query.toLowerCase())));
    }
  }
  
  // Helper methods to safely get data from related boxes
  String _getDepartureName(Box departureBox, String departureId) {
    try {
      final departure = departureBox.get(departureId);
      return departure != null ? departure['name'] ?? 'Unknown' : 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }
  
  String _getArrivalName(Box arrivalBox, String arrivalId) {
    try {
      final arrival = arrivalBox.get(arrivalId);
      return arrival != null ? arrival['name'] ?? 'Unknown' : 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }
  
  String _getPlateNumber(Box vehicleBox, String vehicleId) {
    try {
      final vehicle = vehicleBox.get(vehicleId);
      return vehicle != null ? vehicle['plateNumber'] ?? 'Unknown' : 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  void sortById() {
    sortAsc.value = !sortAsc.value;
    filteredReports.sort((a, b) {
      final idA = int.tryParse(a['tripId'] ?? '') ?? 0;
      final idB = int.tryParse(b['tripId'] ?? '') ?? 0;
      return sortAsc.value ? idA.compareTo(idB) : idB.compareTo(idA);
    });
    filteredReports.refresh();
  }

  void sortByArrival() {
    sortAsc.value = !sortAsc.value;
    filteredReports.sort((a, b) {
      final depA = a['departure']?.toLowerCase() ?? '';
      final depB = b['departure']?.toLowerCase() ?? '';
      return sortAsc.value ? depA.compareTo(depB) : depB.compareTo(depA);
    });
    filteredReports.refresh();
  }
}

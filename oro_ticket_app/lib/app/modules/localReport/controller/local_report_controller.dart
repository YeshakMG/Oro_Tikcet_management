import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

import 'package:oro_ticket_app/data/locals/models/trip_model.dart';
import 'package:oro_ticket_app/data/locals/models/vehicle_model.dart';
import 'package:oro_ticket_app/data/locals/models/departure_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/models/arrival_terminal_model.dart';
import 'package:oro_ticket_app/data/locals/hive_boxes.dart';

class TripReportItem {
  final String departureName;
  final String arrivalName;
  final String plateNumber;
  final String plateRegion;
  final String vehicleLevel;
  final String associationName;
  final double price; // tariff
  final double serviceCharge;
  final double totalPrice; // totalPaid

  TripReportItem({
    required this.departureName,
    required this.arrivalName,
    required this.plateNumber,
    required this.plateRegion,
    required this.vehicleLevel,
    required this.associationName,
    required this.price,
    required this.serviceCharge,
    required this.totalPrice,
  });
}

class LocalReportController extends GetxController {
  RxList<TripReportItem> allTrips = <TripReportItem>[].obs;
  RxList<TripReportItem> filteredTrips = <TripReportItem>[].obs;
  RxBool sortAsc = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadTripsFromHive();
  }

  Future<void> loadTripsFromHive() async {
    print("📥 Loading trips from Hive...");
    try {
      final tripBox = Hive.box<TripModel>(HiveBoxes.tripBox);
      final vehicleBox = Hive.box<VehicleModel>(HiveBoxes.vehiclesBox);
      final departureBox =
          Hive.box<DepartureTerminalModel>(HiveBoxes.departureTerminalsBox);
      final arrivalBox =
          Hive.box<ArrivalTerminalModel>(HiveBoxes.arrivalTerminalsBox);

      print("📦 tripBox length: ${tripBox.length}");
      if (tripBox.isEmpty) {
        print("❌ tripBox is empty — no data.");
        allTrips.clear();
        filteredTrips.clear();
        return;
      }

      final loadedTrips = tripBox.values.map((trip) {
        final vehicle =
            vehicleBox.values.firstWhereOrNull((v) => v.id == trip.vehicleId);
        final departure = departureBox.values
            .firstWhereOrNull((d) => d.id == trip.departureTerminalId);
        final arrival = arrivalBox.values
            .firstWhereOrNull((a) => a.id == trip.arrivalTerminalId);

        return TripReportItem(
          departureName: departure?.name ?? 'Unknown',
          arrivalName: arrival?.name ?? 'Unknown',
          plateNumber: vehicle?.plateNumber ?? 'Unknown',
          plateRegion: vehicle?.plateRegion ?? 'Unknown',
          vehicleLevel: vehicle?.vehicleLevel ?? 'Unknown',
          associationName: vehicle?.associationName ?? 'Unknown',
          price: trip.tariff,
          serviceCharge: trip.serviceCharge,
          totalPrice: trip.totalPaid,
        );
      }).toList();

      allTrips.assignAll(loadedTrips);
      filteredTrips.assignAll(loadedTrips);

      print("✅ Loaded \${allTrips.length} trips with full info.");
    } catch (e, st) {
      print("❌ Error loading trips from Hive: \$e");
      print(st);
      allTrips.clear();
      filteredTrips.clear();
    }
  }

  void searchTrips(String query) {
    if (query.isEmpty) {
      filteredTrips.assignAll(allTrips);
      return;
    }
    final lowerQuery = query.toLowerCase();
    filteredTrips.assignAll(allTrips.where((trip) {
      return trip.departureName.toLowerCase().contains(lowerQuery) ||
          trip.arrivalName.toLowerCase().contains(lowerQuery) ||
          trip.plateNumber.toLowerCase().contains(lowerQuery) ||
          trip.plateRegion.toLowerCase().contains(lowerQuery) ||
          trip.vehicleLevel.toLowerCase().contains(lowerQuery) ||
          trip.associationName.toLowerCase().contains(lowerQuery);
    }).toList());
  }

  void sortByDepartureName() {
    sortAsc.value = !sortAsc.value;
    filteredTrips.sort((a, b) {
      final depA = a.departureName.toLowerCase();
      final depB = b.departureName.toLowerCase();
      return sortAsc.value ? depA.compareTo(depB) : depB.compareTo(depA);
    });
    filteredTrips.refresh();
  }

  void sortByPrice() {
    sortAsc.value = !sortAsc.value;
    filteredTrips.sort((a, b) {
      return sortAsc.value
          ? a.price.compareTo(b.price)
          : b.price.compareTo(a.price);
    });
    filteredTrips.refresh();
  }

  Future<void> generatePDFReport() async {
    try {
      final pdf = pw.Document();

      // Add title page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Oromia Transport Agency',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text('Local Trip Report',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text('Generated on: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 10),
                pw.Text('Total Records: ${filteredTrips.length}',
                    style: const pw.TextStyle(fontSize: 12)),
              ],
            );
          },
        ),
      );

      // Add data table
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) {
            return [
              pw.Table.fromTextArray(
                headers: [
                  'Departure',
                  'Arrival',
                  'Plate Number',
                  'Region',
                  'Level',
                  'Association',
                  'Price (ETB)',
                  'Service Charge (ETB)',
                  'Total Price (ETB)',
                ],
                data: filteredTrips.map((trip) {
                  return [
                    trip.departureName,
                    trip.arrivalName,
                    trip.plateNumber,
                    trip.plateRegion,
                    trip.vehicleLevel,
                    trip.associationName,
                    trip.price.toStringAsFixed(2),
                    trip.serviceCharge.toStringAsFixed(2),
                    trip.totalPrice.toStringAsFixed(2),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignment: pw.Alignment.centerLeft,
                headerAlignment: pw.Alignment.centerLeft,
              ),
            ];
          },
        ),
      );

      final outputDir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'local_trip_report_$timestamp.pdf';
      final file = File('${outputDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      print('✅ PDF generated at: ${file.path}');

      // Show success dialog with options
      await _showPDFFeedbackDialog(file);

    } catch (e) {
      print('❌ Error generating PDF: $e');
      Get.snackbar(
        "Error",
        "Failed to generate PDF report: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _showPDFFeedbackDialog(File pdfFile) async {
    final result = await Get.dialog(
      AlertDialog(
        title: const Text('PDF Report Generated'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report saved to:'),
            Text(pdfFile.path, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
            const SizedBox(height: 16),
            const Text('What would you like to do?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: 'open'),
            child: const Text('Open PDF'),
          ),
          TextButton(
            onPressed: () => Get.back(result: 'share'),
            child: const Text('Share PDF'),
          ),
          TextButton(
            onPressed: () => Get.back(result: 'close'),
            child: const Text('Close'),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (result == 'open') {
      await _openPDF(pdfFile);
    } else if (result == 'share') {
      await _sharePDF(pdfFile);
    }
  }

  Future<void> _openPDF(File pdfFile) async {
    try {
      final result = await OpenFile.open(pdfFile.path);
      if (result.type != ResultType.done) {
        Get.snackbar(
          "Warning",
          "Could not open PDF automatically. File saved at: ${pdfFile.path}",
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to open PDF: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _sharePDF(File pdfFile) async {
    try {
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'Trip Report - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
        subject: 'Oromia Transport Agency - Trip Report',
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to share PDF: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

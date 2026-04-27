import 'dart:convert';

class ExitTicketQRData {
  final String vehicleId;
  final String plateNumber;
  final String originTerminalId;
  final String? checkinDate;
  final String? notes;
  final DateTime timestamp;

  ExitTicketQRData({
    required this.vehicleId,
    required this.plateNumber,
    required this.originTerminalId,
    this.checkinDate,
    this.notes,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'vehicle_id': vehicleId,
        'plate_number': plateNumber,
        'origin_terminal_id': originTerminalId,
        'checkin_date': checkinDate,
        'notes': notes,
        'timestamp': timestamp.toIso8601String(),
      };

  String toQRString() {
    final jsonString = jsonEncode(toJson());

    final bytes = utf8.encode(jsonString);
    return base64Encode(bytes);
  }

  static ExitTicketQRData fromQRString(String qrString) {
    final parts = qrString.split('|');
    return ExitTicketQRData(
      vehicleId: parts[0],
      plateNumber: parts[1],
      originTerminalId: parts[2],
      checkinDate: parts[3].isNotEmpty ? parts[3] : null,
      notes: parts[4].isNotEmpty ? parts[4] : null,
      timestamp: DateTime.parse(parts[5]),
    );
  }
}

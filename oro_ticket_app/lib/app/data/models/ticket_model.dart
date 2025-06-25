class Ticket {
  String plateNumber;
  String region;
  String level;
  int seatCapacity;
  String tripId;
  String departure;
  String destination;
  String date;
  String time;
  String status;
  String employeeName;

  Ticket({
    required this.plateNumber,
    required this.region,
    required this.level,
    required this.seatCapacity,
    required this.tripId,
    required this.departure,
    required this.destination,
    required this.date,
    required this.time,
    required this.status,
    required this.employeeName,
  });

  static Ticket dummyTicket() {
    return Ticket(
      plateNumber: '3ABC123',
      region: 'Oromia',
      level: '2',
      seatCapacity: 36,
      tripId: 'TRP-2023-0875',
      departure: 'Addis Ababa',
      destination: 'Jimma',
      date: '2023-11-15',
      time: '08:30 AM',
      status: 'Confirmed',
      employeeName: 'Tensae Tefera',
    );
  }
}
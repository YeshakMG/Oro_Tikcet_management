import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/ticket_model.dart';




class TicketDetailView extends StatelessWidget {
  final Ticket ticket;

  const TicketDetailView({Key? key, required this.ticket}) : super(key: key); // <-- ✅ ticket named parameter

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ticket Detail"), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildRow("Plate Number", ticket.plateNumber),
            _buildRow("Trip ID", ticket.tripId),
            _buildRow("Region", ticket.region),
            _buildRow("Level", ticket.level),
            _buildRow("Seat Capacity", ticket.seatCapacity.toString()),
            _buildRow("Departure", ticket.departure),
            _buildRow("Destination", ticket.destination),
            _buildRow("Date", ticket.date),
            _buildRow("Time", ticket.time),
            _buildRow("Status", ticket.status),
            _buildRow("Employee Name", ticket.employeeName),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }
}

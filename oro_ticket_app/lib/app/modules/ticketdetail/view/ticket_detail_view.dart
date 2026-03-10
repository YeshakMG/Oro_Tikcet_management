import 'package:flutter/material.dart';
import 'package:oro_ticket_app/widgets/app_scafold.dart';
import '../../../data/models/ticket_model.dart';

class TicketDetailView extends StatelessWidget {
  final Ticket ticket;

  const TicketDetailView({Key? key, required this.ticket}) : super(key: key); // <-- ✅ ticket named parameter

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final paddingHorizontal = size.width * 0.04; // 4% of screen width
    final paddingVertical = size.height * 0.02; // 2% of screen height

    return AppScaffold(
      title: "Ticket Details",
      userName: "Employee Name",
      currentBottomNavIndex: 1,
      showBottomNavBar: true,
      body: Padding(
        padding: EdgeInsets.all(paddingHorizontal),
        child: ListView(
          children: [
            _buildRow("Plate Number", ticket.plateNumber, paddingVertical),
            _buildRow("Trip ID", ticket.tripId, paddingVertical),
            _buildRow("Region", ticket.region, paddingVertical),
            _buildRow("Level", ticket.level, paddingVertical),
            _buildRow("Seat Capacity", ticket.seatCapacity.toString(), paddingVertical),
            _buildRow("Departure", ticket.departure, paddingVertical),
            _buildRow("Destination", ticket.destination, paddingVertical),
            _buildRow("Date", ticket.date, paddingVertical),
            _buildRow("Time", ticket.time, paddingVertical),
            _buildRow("Status", ticket.status, paddingVertical),
            _buildRow("Employee Name", ticket.employeeName, paddingVertical),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String title, String value, double paddingVertical) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: paddingVertical * 0.75),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }
}

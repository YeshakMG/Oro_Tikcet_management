import 'package:hive/hive.dart';
import 'package:oro_ticket_app/data/locals/models/terminal_destination.dart';
part 'vehicle_route.g.dart';

@HiveType(typeId: 9)
class VehicleRoute extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String vehicleId;

  @HiveField(2)
  final String terminalDestinationId;

  @HiveField(3)
  final DateTime? assignedAt;

  @HiveField(4)
  final DateTime? unassignedAt;

  @HiveField(5)
  final bool isOnTemporary;

  @HiveField(6)
  final TerminalDestination? terminalDestination;

  VehicleRoute({
    required this.id,
    required this.vehicleId,
    required this.terminalDestinationId,
    this.assignedAt,
    this.unassignedAt,
    required this.isOnTemporary,
    this.terminalDestination,
  });

  factory VehicleRoute.fromJson(Map<String, dynamic> json) {
    return VehicleRoute(
      id: json['id'],
      vehicleId: json['vehicle_id'],
      terminalDestinationId: json['terminal_destination_id'],
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'])
          : null,
      unassignedAt: json['unassigned_at'] != null
          ? DateTime.parse(json['unassigned_at'])
          : null,
      isOnTemporary: json['is_on_temporary'] ?? false,
      terminalDestination: json['terminalDestination'] != null
          ? TerminalDestination.fromJson(json['terminalDestination'])
          : null,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';

class DrawerItems {
  static const List<Map<String, dynamic>> items = [
    {
      'title': 'Vehicles',
      'icon': Icons.directions_car,
    },
    {
      'title': 'Vehicle categories',
      'icon': Icons.directions_bus,
    },
    {
      'title': 'Terminal Name',
      'icon': Icons.location_on,
    },
    {
      'title': 'Arrival Terminal',
      'icon': Icons.place,
    },
    {
      'title': 'Tariff',
      'icon': Icons.price_change,
    },
    {
      'title': 'Logout',
      'icon': Icons.logout,
      'isDividerNeeded': true,
      'color': AppColors.error,
    },
  ];
}

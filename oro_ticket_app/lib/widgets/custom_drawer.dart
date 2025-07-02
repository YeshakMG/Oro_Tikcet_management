import 'package:flutter/material.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/core/constants/drawer_items.dart';
import 'package:oro_ticket_app/core/constants/typography.dart';
import 'package:oro_ticket_app/widgets/drawer_item_widget.dart';

class CustomDrawer extends StatelessWidget {
  final String userName;
  final Function(String)? onItemSelected;

  const CustomDrawer({
    super.key,
    required this.userName,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            CustomDrawerHeader(
              userName: userName,
            ),
            SizedBox(
              height: 20,
            ),
            ...DrawerItems.items.map((item) {
              final widget = DrawerItem(
                title: item['title'],
                icon: item['icon'],
                color: item['color'],
                onTap: () => onItemSelected?.call(item['title']),
              );
              return widget;
            }).toList(),
          ],
        ),
      ),
    );
  }
}

class CustomDrawerHeader extends StatelessWidget {
  final String userName;
  const CustomDrawerHeader({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: const BoxDecoration(
        color: AppColors.backgroundAlt,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Image.asset(
                'assets/logo/OTA_logo.png',
                height: 100,
              ),
            ),
            const SizedBox(height: 10),
            Text(userName, style: AppTextStyles.heading2),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/app/modules/arrivals/views/arrival_view.dart';
import 'package:oro_ticket_app/app/modules/localReport/view/local_report_view.dart';
import 'package:oro_ticket_app/app/modules/ticket/view/ticket_view.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/widgets/bottom_navbar.dart';
import 'package:oro_ticket_app/widgets/custom_drawer.dart';

class AppScaffold extends StatefulWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool showBottomNavBar;
  final String userName;
  final int currentBottomNavIndex;
  final Function(int)? onBottomNavTap;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.showBottomNavBar = true,
    required this.userName,
    this.currentBottomNavIndex = 0,
    this.onBottomNavTap,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: AppColors.primary,
    ));
    return Scaffold(
      drawer: CustomDrawer(
        userName: widget.userName,
        onItemSelected: (item) {
          switch (item) {
            case 'Vehicles':
              Get.toNamed('/vehicles');
              break;
            case 'Vehicle categories':
              Get.toNamed('/fleet-type');
              break;
            case 'Arrival Terminal':
              Get.to(ArrivalLocationView());
              break;
          }
        },
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  Text(widget.title,
                      style: const TextStyle(color: Colors.white)),
                  Row(children: widget.actions ?? []),
                ],
              ),
            ),
            // Body Content
            Expanded(child: widget.body),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNavBar
          ? BottomNavBar(
              currentIndex: widget.currentBottomNavIndex,
              onTap: widget.onBottomNavTap ??
                  (index) {
                    // Default navigation behavior
                    switch (index) {
                      case 0:
                        Get.offAllNamed('/home');
                        break;
                      case 1:
                        Get.to(TicketView());
                        break;
                      case 2:
                        Get.to(LocalReportView());
                        break;
                    }
                  },
            )
          : null,
    );
  }
}

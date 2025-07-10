import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/app/modules/Tarrif/view/tariif_view.dart';
import 'package:oro_ticket_app/app/modules/arrivals/views/arrival_view.dart';
import 'package:oro_ticket_app/app/modules/departure/view/departure_view.dart';
import 'package:oro_ticket_app/app/modules/home/controllers/home_controller.dart';
import 'package:oro_ticket_app/app/modules/localReport/view/local_report_view.dart';
import 'package:oro_ticket_app/app/modules/sign_in/services/auth_service.dart';
import 'package:oro_ticket_app/app/modules/ticket/view/ticket_view.dart';
import 'package:oro_ticket_app/app/modules/vehicles/views/vehicles_view.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/core/constants/typography.dart';
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
  final homeController = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: AppColors.primary,
    ));

    return Obx(() {
      final user = homeController.user.value;
      final companyName = homeController.companyName.value;

      return Scaffold(
        drawer: CustomDrawer(
          userName: user?.fullName ?? 'Employee',
          companyLogoUrl: homeController.companyLogoUrl.value,
          companyName: companyName,
          onItemSelected: (item) async {
            switch (item) {
              case 'Vehicles':
                Get.to(VehiclesView());
                break;
              // case 'Vehicle categories':
              //   Get.toNamed('/fleet-type');
              //   break;
              case 'Terminal Name':
                Get.to(DepartureView());
                break;
              case 'Arrival Terminal':
                Get.to(ArrivalLocationView());
                break;
              case 'Tariff':
                Get.to(TariffView());
                break;
              case 'Logout':
                confirmLogout();
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    Text(widget.title, style: AppTextStyles.subtitle1),
                    Row(children: widget.actions ?? []),
                  ],
                ),
              ),
              Expanded(child: widget.body),
            ],
          ),
        ),
        bottomNavigationBar: widget.showBottomNavBar
            ? BottomNavBar(
                currentIndex: widget.currentBottomNavIndex,
                onTap: widget.onBottomNavTap ??
                    (index) {
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
    });
  }
}

Future<void> confirmLogout() async {
  final AuthService authService = Get.find<AuthService>();
  final result = await Get.dialog<bool>(
    AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: const Text('Logout', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
    barrierDismissible: true,
  );

  if (result == true) {
    await authService.logout();
    Get.offAllNamed('/sign-in');
  }
}

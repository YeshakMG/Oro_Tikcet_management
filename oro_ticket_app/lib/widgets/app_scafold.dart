import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/app/modules/arrivals/views/arrival_view.dart';
import 'package:oro_ticket_app/app/modules/departure/view/departure_view.dart';
import 'package:oro_ticket_app/app/modules/home/controllers/home_controller.dart';
import 'package:oro_ticket_app/app/modules/localReport/view/local_report_view.dart';
import 'package:oro_ticket_app/app/modules/sign_in/services/auth_service.dart';
import 'package:oro_ticket_app/app/modules/ticket/view/ticket_view.dart';
import 'package:oro_ticket_app/app/modules/vehicles/views/vehicles_view.dart';
import 'package:oro_ticket_app/app/routes/app_pages.dart';
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
                Get.toNamed(Routes.VEHICLES);
                break;
              // case 'Vehicle categories':
              //   Get.toNamed('/fleet-type');
              //   break;
              case 'Terminal Name':
                Get.toNamed(Routes.DEPARTURE);
                break;
              case 'Arrival Terminal':
                Get.toNamed(Routes.ARRIVALS);
                break;
              // case 'Tariff':
              //   Get.to(TariffView());
              //   break;
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
  final authService = Get.find<AuthService>();
  final isLoading = false.obs;
  String? errorMessage;

  print('🔄 Logout confirmation dialog shown');

  // Close any existing snackbars before showing dialog
  try {
    Get.closeCurrentSnackbar();
  } catch (e) {
    // Ignore if no snackbar to close
  }

  final result = await Get.dialog<bool>(
    Obx(() => AlertDialog(
      title: const Text('Confirm Logout'),
      content: isLoading.value
          ? const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Logging out...'),
              ],
            )
          : errorMessage != null
              ? Text(errorMessage!)
              : const Text('Are you sure you want to logout?'),
      actions: isLoading.value
          ? null // Disable actions while loading
          : errorMessage != null
              ? [
                  TextButton(
                    onPressed: () {
                      print('👌 User acknowledged error message');
                      Get.back(result: false);
                    },
                    child: const Text('OK'),
                  ),
                ]
              : [
                  TextButton(
                    onPressed: () {
                      print('❌ User cancelled logout');
                      Get.back(result: false);
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      print('✅ User confirmed logout - starting logout process');
                      isLoading.value = true;
                      errorMessage = null; // Clear any previous error

                      print('🚀 Executing logout service...');
                      final logoutSuccess = await authService.logout();

                      if (logoutSuccess) {
                        print('✅ Logout successful');
                        Get.back(result: true);
                      } else {
                        print('❌ Logout aborted due to unsynced data');
                        isLoading.value = false;
                        errorMessage = 'You have unsynced trips and/or service charges. Please sync your data before logging out.';
                        // Dialog stays open with error message
                      }
                    },
                    child: const Text('Logout', style: TextStyle(color: Colors.red)),
                  ),
                ],
    )),
  );

  if (result != true) {
    print('🚫 Logout cancelled or failed');
  }
}

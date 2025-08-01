import 'package:get/get.dart';

import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/sign_in/bindings/sign_in_binding.dart';
import '../modules/sign_in/views/sign_in_view.dart';
import '../modules/splash_screen/bindings/splash_screen_binding.dart';
import '../modules/splash_screen/views/splash_screen_view.dart';

import '../modules/vehicles/bindings/vehicles_bindings.dart';
import '../modules/vehicles/views/vehicles_view.dart';

import '../modules/fleettype/bindings/fleettype_bindings.dart';
import '../modules/fleettype/views/fleettype_view.dart';

import '../modules/arrivals/bindings/arrival_bindings.dart';
import '../modules/arrivals/views/arrival_view.dart';


part 'app_routes.dart';

class AppPages {
  AppPages._();

  // static const INITIAL = Routes.HOME;
  static const INITIAL = Routes.SPLASH_SCREEN;

  static final routes = [
    GetPage(
      name: _Paths.SPLASH_SCREEN,
      page: () => SplashScreenView(),
      binding: SplashScreenBinding(),
    ),
    GetPage(
      name: _Paths.SIGN_IN,
      page: () => SignInView(),
      binding: SignInBinding(),
    ),
    GetPage(
      name: _Paths.HOME,
      page: () =>  HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.VEHICLES, 
      page: () => VehiclesView(),
      binding: VehiclesBindings(),
      
      ),
    GetPage(name: _Paths.FLEET_TYPE, 
      page: () => FleetTypeView(), 
      binding: FleetTypeBindings(), 
      ),




  ];
}

import 'package:get/get.dart';

class TariffController extends GetxController {
  var selectedArrival = ''.obs;
  var arrivals = ['Adama', 'Addis Ababa', 'Jimma', 'Bale'].obs;

  var tariffs = <Map<String, String>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchTariffs();
  }

  void fetchTariffs() {
    tariffs.value = [
      {"level": "Level 1", "fleet_category": "Mini Bus"},
      {"level": "Level 2", "fleet_category": "Coaster"},
      {"level": "Level 3", "fleet_category": "Bus"},
    ];
  }

  void filterTariffs(String arrival) {
    selectedArrival.value = arrival;
    // Apply filter logic if needed
  }
}

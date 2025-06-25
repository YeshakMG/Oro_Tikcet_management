import 'package:get/get.dart';

class ArrivalLocationController extends GetxController {
  var Locations = <Map<String, dynamic>>[].obs;

  final allLocations = [
    {"id": 1, "name": "Autobis tera"},
    {"id": 2, "name": "Shashmanee"},
    {"id": 3, "name": "Maqqii"},
    {"id": 4, "name": "Autobis tera"},
    {"id": 5, "name": "Shashmanee"},
    {"id": 6, "name": "Maqqii"},
    {"id": 7, "name": "Autobis tera"},
    {"id": 8, "name": "Shashmanee"},
    {"id": 9, "name": "Maqqii"},
    {"id": 10, "name": "Autobis tera"},
    {"id": 11, "name": "Shashmanee"},
    {"id": 12, "name": "Maqqii"},
  ];

  @override
  void onInit() {
    Locations.value = List.from(allLocations);
    super.onInit();
  }

  void filterLocations(String query) {
    if (query.isEmpty) {
      Locations.value = List.from(allLocations);
    } else {
      Locations.value = allLocations.where((item) {
        final location = item['name'];
        return location != null &&
            location.toString().toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
  }
}

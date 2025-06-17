import 'package:get/get.dart';

class ArrivalLocationController extends GetxController {
  var Locations = <Map<String, dynamic>>[].obs;

  final allLocations = [
    {"id": 1, "name": "Autobis tera"},
    {"id": 2, "name": "Shashmanee"},
    {"id": 3, "name": "Maqqii"},
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
      final location = item['location'];
      return location != null &&
          location.toString().toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
}

}

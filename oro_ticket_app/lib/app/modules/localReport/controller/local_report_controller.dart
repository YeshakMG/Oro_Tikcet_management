import 'package:get/get.dart';


class LocalReportController extends GetxController {

  RxList<Map<String, String>> allReports = <Map<String, String>>[
    {'tripId': '1009', 'departure': 'Addis Ababa', 'destination': 'Mojjo', 'date': '2023-10-01', 'time': '08:00 AM', 'status': 'Completed'},
    {'tripId': '1010', 'departure': 'Addis Ababa', 'destination': 'Shasmane', 'date': '2023-10-02', 'time': '09:00 AM', 'status': 'Completed'},
    {'tripId': '1011', 'departure': 'Addis Ababa', 'destination': 'Battuu', 'date': '2023-10-03', 'time': '10:00 AM', 'status': 'Pending'},
    {'tripId': '1012', 'departure': 'Addis Ababa', 'destination': 'Dire-Dawa', 'date': '2023-10-04', 'time': '11:00 AM', 'status': 'Pending'},
    {'tripId': '1013', 'departure': 'Addis Ababa', 'destination': 'Hossanna', 'date': '2023-10-05', 'time': '12:00 PM', 'status': 'Completed'},





  ].obs;
  RxList<Map<String, String>> filteredReports = <Map<String, String>>[].obs;
  RxString selectedStatus = ''.obs;
  RxBool sortAsc = true.obs;
  RxString searchQuery = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    filteredReports.assignAll(allReports);
  }
  void searchReports(String query){
    if(query.isEmpty){
      filteredReports.assignAll(allReports);

    }
    else {
      filteredReports.assignAll(allReports.where((report) =>
          report['tripId']!.contains(query) ||
          report['departure']!.toLowerCase().contains(query.toLowerCase())));
    }

  }
  // Toggle and sort by Trip ID
void sortById() {
  sortAsc.value = !sortAsc.value;
  filteredReports.sort((a, b) {
    final idA = int.tryParse(a['tripId'] ?? '') ?? 0;
    final idB = int.tryParse(b['tripId'] ?? '') ?? 0;
    return sortAsc.value ? idA.compareTo(idB) : idB.compareTo(idA);
  });
  filteredReports.refresh(); // important for reactivity
}

// Toggle and sort by Departure Location
void sortByArrival() {
  sortAsc.value = !sortAsc.value;
  filteredReports.sort((a, b) {
    final depA = a['departure']?.toLowerCase() ?? '';
    final depB = b['departure']?.toLowerCase() ?? '';
    
    return sortAsc.value ? depA.compareTo(depB) : depB.compareTo(depA);
  });
  filteredReports.refresh(); // important for reactivity
}





}

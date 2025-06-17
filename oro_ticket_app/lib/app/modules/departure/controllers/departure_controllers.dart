import 'package:get/get.dart';

class Departure {
  final int no;
  final String terminalName;

  Departure({required this.no, required this.terminalName});
}

class DepartureController extends GetxController {
  // Your controller logic here
  RxList<Departure> departures = <Departure>[
    Departure(no: 1, terminalName: 'Terminal A'),
    Departure(no: 2, terminalName: 'Terminal B'),
    Departure(no: 3, terminalName: 'Terminal C'),
    Departure(no: 4, terminalName: 'Terminal D'),
    Departure(no: 5, terminalName: 'Terminal E'),
  ].obs;


}

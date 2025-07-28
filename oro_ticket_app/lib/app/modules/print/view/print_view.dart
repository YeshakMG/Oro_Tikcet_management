import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/print_controller.dart';
import 'package:hive/hive.dart';

class PrintView extends StatelessWidget {
  final PrintController printController = Get.put(PrintController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Print Ticket'),
      ),
      body: Center(
        child: Text('Print Ticket View'),
      ),
    );
  }
}

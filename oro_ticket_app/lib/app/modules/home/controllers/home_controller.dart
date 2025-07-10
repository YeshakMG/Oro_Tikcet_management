import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:oro_ticket_app/app/modules/sign_in/models/user_model.dart';
import 'package:oro_ticket_app/app/modules/sign_in/services/auth_service.dart';

class HomeController extends GetxController {
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxString companyName = ''.obs;
  final companyLogoUrl = ''.obs;
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  final storage = FlutterSecureStorage();
  @override
  void onInit() {
    super.onInit();
    loadUser();
  }

  Future<void> loadUser() async {
    final loadedUser = await AuthService().getUser();
    user.value = loadedUser;
    if (loadedUser?.companyId != null) {
      await fetchCompanyName();
    }
  }

  Future<void> fetchCompanyName() async {
    final id = user.value?.companyId;
    if (id == null) return;

    try {
      final token = await storage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse('$baseUrl/companies/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        companyName.value = data['data']['name'] ?? 'Unknown Company';
        companyLogoUrl.value = data['data']['logo_url'] ?? '';
      } else {
        debugPrint('Failed to fetch company name: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching company name: $e');
    }
  }

  void resetDashboard() {
    // Implement reset logic
    
  }
}

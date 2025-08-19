import 'package:hive/hive.dart';
import 'package:oro_ticket_app/data/locals/models/user_model.dart';

class UserStorageService {
  static const _boxName = 'userData';

  static Future<Box<UserModel>> get _box async {
    return await Hive.openBox<UserModel>(_boxName);
  }

  static Future<void> saveUser(UserModel user) async {
    final box = await _box;
    await box.put('currentUser', user);
  }

  static Future<UserModel?> getUser() async {
    final box = await _box;
    return box.get('currentUser');
  }

  static Future<void> clearUser() async {
    final box = await _box;
    await box.clear();
  }
}
import 'package:hive/hive.dart';

// TODO: Run 'flutter pub run build_runner build' to generate the part file
// part 'user_model.g.dart';

@HiveType(typeId: 1)
class UserModel extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? username;

  @HiveField(2)
  String? fullName;

  @HiveField(3)
  String? companyName;

  @HiveField(4)
  String? role;

  @HiveField(5)
  String? token;

  UserModel({
    this.id,
    this.username,
    this.fullName,
    this.companyName,
    this.role,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      fullName: json['fullName'],
      companyName: json['companyName'],
      role: json['role'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'companyName': companyName,
      'role': role,
      'token': token,
    };
  }
}
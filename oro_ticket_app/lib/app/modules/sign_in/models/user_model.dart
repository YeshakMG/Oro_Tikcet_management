class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String roleId;
  final String? companyId;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.roleId,
    this.companyId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'] ?? '',
      roleId: json['role_id'],
      companyId: json['company_id'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'role_id': roleId,
        'company_id': companyId,
      };
}

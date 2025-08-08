class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String roleId;
  final String? companyName;
  final String? logoUrl;
  final String companyId;
  final String? companyPhoneNo;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.roleId,
    required this.companyId,
    this.companyName,
    this.logoUrl,
    this.companyPhoneNo,
  });

  factory UserModel.fromLoginJson(Map<String, dynamic> json) {
    // Try nested parsing
    final companyUser = json['company_user'];
    final user = companyUser != null ? companyUser['user'] : json;
    final company = companyUser != null ? companyUser['company'] : null;

    return UserModel(
      id: user?['id'] ?? '',
      email: user?['email'] ?? '',
      fullName: user?['full_name'] ?? '',
      roleId: user?['role_id'] ?? '',
      companyId: companyUser?['company_id'] ?? '',
      companyName:
          company?['name'] ?? json['company_name'] ?? 'Unknown Company',
      logoUrl: company?['logo_url'],
      companyPhoneNo: company?['phone'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'role_id': roleId,
        'company_id': companyId,
        'name': companyName,
        'logo_url': logoUrl,
        'phone_no': companyPhoneNo,
      };
}

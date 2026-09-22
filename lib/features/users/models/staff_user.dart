class StaffUser {
  const StaffUser({
    required this.id,
    required this.name,
    required this.email,
    required this.isActive,
    required this.role,
    this.phone,
    this.branchId,
    this.branchName,
  });

  factory StaffUser.fromJson(Map<String, dynamic> json) => StaffUser(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        branchId: json['branch_id'] as int?,
        branchName: json['branch_name'] as String?,
        isActive: json['is_active'] as bool,
        role: json['role'] as String?,
      );

  final int id;
  final String name;
  final String email;
  final String? phone;
  final int? branchId;
  final String? branchName;
  final bool isActive;
  final String? role;
}

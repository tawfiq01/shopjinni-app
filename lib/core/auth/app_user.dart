class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
    required this.permissions,
    this.phone,
    this.branchId,
    this.branchName,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      branchId: json['branch_id'] as int?,
      branchName: json['branch_name'] as String?,
      roles: (json['roles'] as List<dynamic>? ?? []).cast<String>(),
      permissions: (json['permissions'] as List<dynamic>? ?? []).cast<String>(),
    );
  }

  final int id;
  final String name;
  final String email;
  final String? phone;
  final int? branchId;
  final String? branchName;
  final List<String> roles;
  final List<String> permissions;

  bool hasRole(String role) => roles.contains(role);

  bool can(String permission) => permissions.contains(permission);
}

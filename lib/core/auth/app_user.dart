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
    this.companyId,
    this.companyName,
    this.isSuperAdmin = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      branchId: json['branch_id'] as int?,
      branchName: json['branch_name'] as String?,
      companyId: json['company_id'] as int?,
      companyName: json['company_name'] as String?,
      isSuperAdmin: json['is_super_admin'] as bool? ?? false,
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
  final int? companyId;
  final String? companyName;
  final bool isSuperAdmin;
  final List<String> roles;
  final List<String> permissions;

  /// True right after a Google sign-up, before the shop/company details
  /// have been entered — the app should route this user to onboarding
  /// instead of the dashboard until it's false.
  bool get needsOnboarding => companyId == null;

  bool hasRole(String role) => roles.contains(role);

  bool can(String permission) => permissions.contains(permission);
}

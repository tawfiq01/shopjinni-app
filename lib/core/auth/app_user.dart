class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
    required this.permissions,
    this.phone,
    this.avatarUrl,
    this.branchId,
    this.branchName,
    this.companyId,
    this.companyName,
    this.companyLogoUrl,
    this.isSuperAdmin = false,
    this.setupWizardCompleted = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      branchId: json['branch_id'] as int?,
      branchName: json['branch_name'] as String?,
      companyId: json['company_id'] as int?,
      companyName: json['company_name'] as String?,
      companyLogoUrl: json['company_logo_url'] as String?,
      isSuperAdmin: json['is_super_admin'] as bool? ?? false,
      setupWizardCompleted: json['setup_wizard_completed'] as bool? ?? false,
      roles: (json['roles'] as List<dynamic>? ?? []).cast<String>(),
      permissions: (json['permissions'] as List<dynamic>? ?? []).cast<String>(),
    );
  }

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final int? branchId;
  final String? branchName;
  final int? companyId;
  final String? companyName;
  final String? companyLogoUrl;
  final bool isSuperAdmin;
  final bool setupWizardCompleted;
  final List<String> roles;
  final List<String> permissions;

  /// True right after a Google sign-up, before the shop/company details
  /// have been entered — the app should route this user to onboarding
  /// instead of the dashboard until it's false.
  bool get needsOnboarding => companyId == null;

  /// Only the shop owner is walked through the setup wizard — a
  /// Salesperson/Accountant logging in for the first time has no reason
  /// to be sent through "add distributors/staff," most of which they
  /// can't even do. Dismissible (unlike needsOnboarding): the wizard
  /// screen itself can mark it complete without finishing every step.
  bool get needsSetupWizard => !needsOnboarding && !setupWizardCompleted && can('company.manage');

  bool hasRole(String role) => roles.contains(role);

  bool can(String permission) => permissions.contains(permission);
}

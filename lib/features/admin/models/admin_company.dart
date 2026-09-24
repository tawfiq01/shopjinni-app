class AdminCompany {
  const AdminCompany({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    required this.isActive,
    required this.userCount,
    this.subscriptionStatus,
    this.planName,
  });

  factory AdminCompany.fromJson(Map<String, dynamic> json) => AdminCompany(
        id: json['id'] as int,
        name: json['name'] as String,
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        isActive: json['is_active'] as bool,
        userCount: json['user_count'] as int,
        subscriptionStatus: json['subscription_status'] as String?,
        planName: json['plan_name'] as String?,
      );

  final int id;
  final String name;
  final String? address;
  final String? phone;
  final bool isActive;
  final int userCount;
  final String? subscriptionStatus;
  final String? planName;
}

class AdminPlan {
  const AdminPlan({
    required this.id,
    required this.name,
    required this.slug,
    required this.monthlyPrice,
    required this.yearlyPrice,
    this.maxUsers,
    this.maxProducts,
    this.maxBranches,
    required this.trialPeriodDays,
    required this.features,
    required this.isActive,
    required this.sortOrder,
  });

  factory AdminPlan.fromJson(Map<String, dynamic> json) => AdminPlan(
        id: json['id'] as int,
        name: json['name'] as String,
        slug: json['slug'] as String,
        monthlyPrice: double.parse(json['monthly_price'].toString()),
        yearlyPrice: double.parse(json['yearly_price'].toString()),
        maxUsers: json['max_users'] as int?,
        maxProducts: json['max_products'] as int?,
        maxBranches: json['max_branches'] as int?,
        trialPeriodDays: json['trial_period_days'] as int,
        features: (json['features'] as List<dynamic>? ?? []).cast<String>(),
        isActive: json['is_active'] as bool,
        sortOrder: json['sort_order'] as int,
      );

  final int id;
  final String name;
  final String slug;
  final double monthlyPrice;
  final double yearlyPrice;
  final int? maxUsers;
  final int? maxProducts;
  final int? maxBranches;
  final int trialPeriodDays;
  final List<String> features;
  final bool isActive;
  final int sortOrder;
}

class SubscriptionUsage {
  const SubscriptionUsage({required this.current, this.max});

  factory SubscriptionUsage.fromJson(Map<String, dynamic> json) => SubscriptionUsage(
        current: json['current'] as int,
        max: json['max'] as int?,
      );

  final int current;
  final int? max;

  bool get isUnlimited => max == null;
}

class SubscriptionPlanSummary {
  const SubscriptionPlanSummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.maxUsers,
    required this.maxProducts,
    required this.maxBranches,
    required this.features,
  });

  factory SubscriptionPlanSummary.fromJson(Map<String, dynamic> json) => SubscriptionPlanSummary(
        id: json['id'] as int,
        name: json['name'] as String,
        slug: json['slug'] as String,
        // Laravel's decimal cast serializes as a JSON string on the raw
        // /subscription/plans list but a number on the hand-built
        // /company/subscription response — parse via toString() so both
        // shapes work through this one factory.
        monthlyPrice: double.parse(json['monthly_price'].toString()),
        yearlyPrice: double.parse(json['yearly_price'].toString()),
        maxUsers: json['max_users'] as int?,
        maxProducts: json['max_products'] as int?,
        maxBranches: json['max_branches'] as int?,
        features: (json['features'] as List<dynamic>? ?? []).cast<String>(),
      );

  final int id;
  final String name;
  final String slug;
  final double monthlyPrice;
  final double yearlyPrice;
  final int? maxUsers;
  final int? maxProducts;
  final int? maxBranches;
  final List<String> features;
}

class CompanySubscription {
  const CompanySubscription({
    required this.status,
    required this.billingCycle,
    this.trialEndsAt,
    this.currentPeriodEndsAt,
    required this.isLifetime,
    this.paymentDueSince,
    required this.plan,
    required this.usersUsage,
    required this.branchesUsage,
    required this.productsUsage,
  });

  factory CompanySubscription.fromJson(Map<String, dynamic> json) {
    final usage = json['usage'] as Map<String, dynamic>;
    return CompanySubscription(
      status: json['status'] as String,
      billingCycle: json['billing_cycle'] as String,
      trialEndsAt: json['trial_ends_at'] != null ? DateTime.parse(json['trial_ends_at'] as String) : null,
      currentPeriodEndsAt:
          json['current_period_ends_at'] != null ? DateTime.parse(json['current_period_ends_at'] as String) : null,
      isLifetime: json['is_lifetime'] as bool,
      paymentDueSince: json['payment_due_since'] != null ? DateTime.parse(json['payment_due_since'] as String) : null,
      plan: SubscriptionPlanSummary.fromJson(json['plan'] as Map<String, dynamic>),
      usersUsage: SubscriptionUsage.fromJson(usage['users'] as Map<String, dynamic>),
      branchesUsage: SubscriptionUsage.fromJson(usage['branches'] as Map<String, dynamic>),
      productsUsage: SubscriptionUsage.fromJson(usage['products'] as Map<String, dynamic>),
    );
  }

  final String status;
  final String billingCycle;
  final DateTime? trialEndsAt;
  final DateTime? currentPeriodEndsAt;
  final bool isLifetime;
  final DateTime? paymentDueSince;
  final SubscriptionPlanSummary plan;
  final SubscriptionUsage usersUsage;
  final SubscriptionUsage branchesUsage;
  final SubscriptionUsage productsUsage;

  bool get isTrial => status == 'trial';
  bool get isPaymentDue => status == 'payment_due';
  bool get isGrace => status == 'grace';
  bool get isExpired => status == 'expired';
  bool get isSuspended => status == 'suspended';

  /// Mirrors the backend's EnsureSubscriptionActive — matches exactly
  /// which statuses the API itself blocks business routes for.
  bool get isBlocked => isGrace || isExpired || isSuspended;

  int? get trialDaysLeft {
    if (trialEndsAt == null) return null;
    final diff = trialEndsAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }
}

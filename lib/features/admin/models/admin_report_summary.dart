class AdminReportSummary {
  const AdminReportSummary({
    required this.totalCompanies,
    required this.activeCompanies,
    required this.byStatus,
    required this.paymentsThisMonthCount,
    required this.paymentsThisMonthTotal,
  });

  factory AdminReportSummary.fromJson(Map<String, dynamic> json) {
    final byStatus = (json['by_status'] as Map<String, dynamic>? ?? {})
        .map((key, value) => MapEntry(key, value as int));
    final paymentsThisMonth = json['payments_this_month'] as Map<String, dynamic>;

    return AdminReportSummary(
      totalCompanies: json['total_companies'] as int,
      activeCompanies: json['active_companies'] as int,
      byStatus: byStatus,
      paymentsThisMonthCount: paymentsThisMonth['count'] as int,
      paymentsThisMonthTotal: double.parse(paymentsThisMonth['total'].toString()),
    );
  }

  final int totalCompanies;
  final int activeCompanies;
  final Map<String, int> byStatus;
  final int paymentsThisMonthCount;
  final double paymentsThisMonthTotal;
}

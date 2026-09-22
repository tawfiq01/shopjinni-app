class DashboardPeriodStats {
  const DashboardPeriodStats({
    required this.salesTotal,
    required this.salesCount,
    this.profit,
  });

  factory DashboardPeriodStats.fromJson(Map<String, dynamic> json) => DashboardPeriodStats(
        salesTotal: (json['sales_total'] as num).toDouble(),
        salesCount: json['sales_count'] as int,
        profit: json['profit'] == null ? null : (json['profit'] as num).toDouble(),
      );

  final double salesTotal;
  final int salesCount;
  /// Null when the viewer lacks reports.view-cost.
  final double? profit;
}

class DashboardSummary {
  const DashboardSummary({
    required this.today,
    required this.thisMonth,
    required this.lowStockCount,
    required this.totalCustomerDue,
    required this.totalDistributorDue,
    required this.cashPositionTotal,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) => DashboardSummary(
        today: DashboardPeriodStats.fromJson(json['today'] as Map<String, dynamic>),
        thisMonth: DashboardPeriodStats.fromJson(json['this_month'] as Map<String, dynamic>),
        lowStockCount: json['low_stock_count'] as int,
        totalCustomerDue: (json['total_customer_due'] as num).toDouble(),
        totalDistributorDue: (json['total_distributor_due'] as num).toDouble(),
        cashPositionTotal: (json['cash_position_total'] as num).toDouble(),
      );

  final DashboardPeriodStats today;
  final DashboardPeriodStats thisMonth;
  final int lowStockCount;
  final double totalCustomerDue;
  final double totalDistributorDue;
  final double cashPositionTotal;
}

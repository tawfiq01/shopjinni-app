import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reports/application/reports_providers.dart';
import '../../reports/presentation/stock_report_screen.dart';
import '../application/dashboard_providers.dart';

class DashboardSummarySection extends ConsumerWidget {
  const DashboardSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return summaryAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text('Failed to load dashboard summary: $err'),
      ),
      data: (summary) {
        const spacing = 12.0;
        const minCardWidth = 150.0;

        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = (constraints.maxWidth / minCardWidth).floor().clamp(2, 4);
            final cardWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                _StatCard(
                  width: cardWidth,
                  icon: Icons.point_of_sale_outlined,
                  label: "Today's Sales",
                  value: summary.today.salesTotal.toStringAsFixed(2),
                  subtitle: '${summary.today.salesCount} invoice(s)'
                      '${summary.today.profit != null ? ' · profit ${summary.today.profit!.toStringAsFixed(2)}' : ''}',
                ),
                _StatCard(
                  width: cardWidth,
                  icon: Icons.calendar_month_outlined,
                  label: "This Month's Sales",
                  value: summary.thisMonth.salesTotal.toStringAsFixed(2),
                  subtitle: '${summary.thisMonth.salesCount} invoice(s)'
                      '${summary.thisMonth.profit != null ? ' · profit ${summary.thisMonth.profit!.toStringAsFixed(2)}' : ''}',
                ),
                _StatCard(
                  width: cardWidth,
                  icon: Icons.warning_amber_outlined,
                  label: 'Low Stock Alerts',
                  value: '${summary.lowStockCount}',
                  highlight: summary.lowStockCount > 0,
                  onTap: () {
                    ref.read(lowStockOnlyProvider.notifier).set(true);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StockReportScreen()),
                    );
                  },
                ),
                _StatCard(
                  width: cardWidth,
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Customer Due',
                  value: summary.totalCustomerDue.toStringAsFixed(2),
                ),
                _StatCard(
                  width: cardWidth,
                  icon: Icons.local_shipping_outlined,
                  label: 'Distributor Due',
                  value: summary.totalDistributorDue.toStringAsFixed(2),
                ),
                _StatCard(
                  width: cardWidth,
                  icon: Icons.account_balance_outlined,
                  label: 'Cash / Bank / MFS',
                  value: summary.cashPositionTotal.toStringAsFixed(2),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.highlight = false,
    this.onTap,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accentColor = highlight ? Colors.red.shade700 : null;

    return SizedBox(
      width: width,
      child: Card(
        color: highlight ? Colors.red.shade50 : null,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, size: 20, color: accentColor),
                    if (onTap != null) Icon(Icons.chevron_right, size: 18, color: accentColor),
                  ],
                ),
                const SizedBox(height: 8),
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: accentColor),
                ),
                if (subtitle != null)
                  Text(subtitle!, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

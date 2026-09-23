import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_state.dart';
import 'cash_position_screen.dart';
import 'dues_report_screen.dart';
import 'imei_history_screen.dart';
import 'purchase_report_screen.dart';
import 'sales_detail_report_screen.dart';
import 'sales_report_screen.dart';
import 'stock_details_screen.dart';
import 'stock_report_screen.dart';

class ReportsHomeScreen extends ConsumerWidget {
  const ReportsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final canViewPurchaseCost =
        (user?.can('reports.view-cost') ?? false) || (user?.can('purchases.manage') ?? false);

    final tiles = <(String, IconData, WidgetBuilder)>[
      ('Current Stock', Icons.inventory_2_outlined, (_) => const StockReportScreen()),
      ('Current Stock Details', Icons.account_tree_outlined, (_) => const StockDetailsScreen()),
      ('Sales Summary', Icons.point_of_sale_outlined, (_) => const SalesReportScreen()),
      ('Sales Details Report', Icons.receipt_long_outlined, (_) => const SalesDetailReportScreen()),
      if (canViewPurchaseCost)
        ('Purchase Summary', Icons.shopping_bag_outlined, (_) => const PurchaseReportScreen()),
      ('Customer & Distributor Dues', Icons.account_balance_wallet_outlined, (_) => const DuesReportScreen()),
      ('Cash / Bank / MFS Position', Icons.account_balance_outlined, (_) => const CashPositionScreen()),
      ('IMEI History', Icons.history, (_) => const ImeiHistoryScreen()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tiles.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final (label, icon, builder) = tiles[index];
          return Card(
            child: ListTile(
              leading: Icon(icon),
              title: Text(label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: builder)),
            ),
          );
        },
      ),
    );
  }
}

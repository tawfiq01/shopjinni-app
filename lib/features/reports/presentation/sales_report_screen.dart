import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/reports_providers.dart';

class SalesReportScreen extends ConsumerWidget {
  const SalesReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(salesSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sales Summary')),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load sales summary: $err')),
        data: (summary) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${summary.from} to ${summary.to}',
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    _row(context, 'Invoices', '${summary.invoiceCount}'),
                    _row(context, 'Total Sales', summary.totalSales.toStringAsFixed(2)),
                    _row(context, 'Total Discount', summary.totalDiscount.toStringAsFixed(2)),
                    _row(context, 'Total Due', summary.totalDue.toStringAsFixed(2)),
                    if (summary.totalProfit != null)
                      _row(context, 'Total Profit', summary.totalProfit!.toStringAsFixed(2), bold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Daily breakdown', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (summary.byDay.isEmpty) const Text('No sales in this range.'),
            for (final day in summary.byDay)
              ListTile(
                title: Text(day.date),
                subtitle: Text('${day.count} invoice(s)'),
                trailing: Text(day.total.toStringAsFixed(2)),
              ),
            const SizedBox(height: 16),
            Text('By model', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (summary.byModel.isEmpty) const Text('No sales in this range.'),
            for (final row in summary.byModel)
              ListTile(
                title: Text(row.name),
                subtitle: Text('${row.quantity} unit(s)'),
                trailing: Text(row.total.toStringAsFixed(2)),
              ),
            const SizedBox(height: 16),
            Text('By color', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (summary.byColor.isEmpty) const Text('No sales in this range.'),
            for (final row in summary.byColor)
              ListTile(
                title: Text(row.name),
                subtitle: Text('${row.quantity} unit(s)'),
                trailing: Text(row.total.toStringAsFixed(2)),
              ),
            const SizedBox(height: 16),
            Text('By salesperson', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (summary.bySalesperson.isEmpty) const Text('No sales in this range.'),
            for (final row in summary.bySalesperson)
              ListTile(
                title: Text(row.name),
                subtitle: Text('${row.count} invoice(s)'),
                trailing: Text(row.total.toStringAsFixed(2)),
              ),
            const SizedBox(height: 16),
            Text('By customer', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (summary.byCustomer.isEmpty) const Text('No sales in this range.'),
            for (final row in summary.byCustomer)
              ListTile(
                title: Text(row.name),
                subtitle: Text('${row.count} invoice(s)'),
                trailing: Text(row.total.toStringAsFixed(2)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

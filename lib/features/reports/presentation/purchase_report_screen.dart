import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/reports_providers.dart';
import 'purchase_price_history_screen.dart';

class PurchaseReportScreen extends ConsumerWidget {
  const PurchaseReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(purchaseSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Summary')),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load purchase summary: $err')),
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
                    _row('Invoices', '${summary.invoiceCount}'),
                    _row('Total Purchases', summary.totalPurchases.toStringAsFixed(2)),
                    _row('Total Due to Distributors', summary.totalDue.toStringAsFixed(2)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('By distributor', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (summary.byDistributor.isEmpty) const Text('No purchases in this range.'),
            for (final row in summary.byDistributor)
              ListTile(
                title: Text(row.distributorName),
                subtitle: Text('${row.count} invoice(s)'),
                trailing: Text(row.total.toStringAsFixed(2)),
              ),
            const SizedBox(height: 16),
            Text('By product', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (summary.byProduct.isEmpty) const Text('No purchases in this range.'),
            for (final row in summary.byProduct)
              ListTile(
                title: Text(row.displayName),
                subtitle: Text('${row.quantity} unit(s) · avg ${row.avgUnitCost.toStringAsFixed(2)}'),
                trailing: Text(row.total.toStringAsFixed(2)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PurchasePriceHistoryScreen(
                      skuId: row.skuId,
                      displayName: row.displayName,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value)],
      ),
    );
  }
}

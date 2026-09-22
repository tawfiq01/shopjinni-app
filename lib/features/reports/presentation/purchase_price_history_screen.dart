import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/reports_providers.dart';

class PurchasePriceHistoryScreen extends ConsumerWidget {
  const PurchasePriceHistoryScreen({super.key, required this.skuId, required this.displayName});

  final int skuId;
  final String displayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(purchasePriceHistoryProvider(skuId));

    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Price History')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load price history: $err')),
        data: (rows) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(displayName, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (rows.isEmpty) const Text('No purchase batches for this product yet.'),
            for (final row in rows)
              Card(
                child: ListTile(
                  title: Text('${row.unitCost.toStringAsFixed(2)} / unit'),
                  subtitle: Text(
                    '${row.date} · ${row.distributorName} · Inv# ${row.invoiceNumber}\n'
                    'Purchased ${row.quantity}, ${row.remainingQuantity} remaining',
                  ),
                  isThreeLine: true,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

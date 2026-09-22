import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/reports_providers.dart';

class StockMovementHistoryScreen extends ConsumerWidget {
  const StockMovementHistoryScreen({super.key, required this.skuId, required this.displayName});

  final int skuId;
  final String displayName;

  IconData _iconFor(String type) => switch (type) {
        'purchase' => Icons.add_shopping_cart_outlined,
        'sale' => Icons.point_of_sale_outlined,
        'sales_return' => Icons.assignment_return_outlined,
        'purchase_return' => Icons.local_shipping_outlined,
        'transfer_out' || 'transfer_in' => Icons.compare_arrows,
        'adjustment' => Icons.tune,
        'exchange_in' || 'exchange_out' => Icons.swap_horiz,
        _ => Icons.circle_outlined,
      };

  String _labelFor(String type) => switch (type) {
        'purchase' => 'Purchased',
        'sale' => 'Sold',
        'sales_return' => 'Returned by customer',
        'purchase_return' => 'Returned to distributor',
        'transfer_out' => 'Transferred out',
        'transfer_in' => 'Transferred in',
        'adjustment' => 'Stock adjustment',
        'exchange_in' => 'Received in exchange',
        'exchange_out' => 'Given out in exchange',
        _ => type,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(stockMovementHistoryProvider(skuId));

    return Scaffold(
      appBar: AppBar(title: const Text('Stock Movement History')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load stock movements: $err')),
        data: (history) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(displayName, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (history.movements.isEmpty) const Text('No stock movements recorded yet.'),
            for (final movement in history.movements)
              ListTile(
                leading: Icon(_iconFor(movement.type)),
                title: Text(_labelFor(movement.type)),
                subtitle: Text('${movement.date} · ${movement.branch}'),
                trailing: Text(
                  '${movement.quantityChange > 0 ? '+' : ''}${movement.quantityChange}'
                  '${movement.unitCost != null ? ' · ${movement.unitCost!.toStringAsFixed(2)}' : ''}',
                  style: TextStyle(
                    color: movement.quantityChange >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

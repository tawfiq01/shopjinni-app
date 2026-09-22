import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/reports_providers.dart';
import '../models/report_models.dart';
import 'stock_movement_history_screen.dart';

class StockReportScreen extends ConsumerWidget {
  const StockReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockAsync = ref.watch(stockReportProvider);
    final lowStockOnly = ref.watch(lowStockOnlyProvider);
    final selectedCategory = ref.watch(stockCategoryFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Stock'),
        actions: [
          Row(
            children: [
              const Text('Low stock only'),
              Switch(
                value: lowStockOnly,
                onChanged: (value) =>
                    ref.read(lowStockOnlyProvider.notifier).set(value),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search brand, model, color or SKU…',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) =>
                  ref.read(stockSearchProvider.notifier).set(value),
            ),
          ),
          Expanded(
            child: stockAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) =>
                  Center(child: Text('Failed to load stock report: $err')),
              data: (report) {
                final rows = report.rows;
                if (rows.isEmpty) {
                  return const Center(child: Text('No stock to show.'));
                }

                final grouped = <String, List<StockReportRow>>{};
                for (final row in rows) {
                  grouped.putIfAbsent(row.productType, () => []).add(row);
                }
                final allCategories = grouped.keys.toList()..sort();
                final categories = selectedCategory == null
                    ? allCategories
                    : allCategories
                          .where((c) => c == selectedCategory)
                          .toList();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: const Text('All'),
                                selected: selectedCategory == null,
                                onSelected: (_) => ref
                                    .read(stockCategoryFilterProvider.notifier)
                                    .set(null),
                              ),
                            ),
                            for (final category in allCategories)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(
                                    '$category (${grouped[category]!.length})',
                                  ),
                                  selected: selectedCategory == category,
                                  onSelected: (_) => ref
                                      .read(
                                        stockCategoryFilterProvider.notifier,
                                      )
                                      .set(
                                        selectedCategory == category
                                            ? null
                                            : category,
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (report.totalValue != null)
                      Container(
                        width: double.infinity,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerLow,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Stock Value',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              report.totalValue!.toStringAsFixed(2),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: categories.isEmpty
                          ? const Center(
                              child: Text('No stock in this category.'),
                            )
                          : ListView(
                              children: [
                                for (final category in categories) ...[
                                  Container(
                                    width: double.infinity,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      '$category (${grouped[category]!.length})',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  for (final row in grouped[category]!)
                                    ListTile(
                                      leading: Icon(
                                        row.imeiTrackingEnabled
                                            ? Icons.fingerprint
                                            : Icons.inventory_2_outlined,
                                      ),
                                      title: Text(row.displayName),
                                      subtitle: Text(
                                        '${row.brand} · Reorder level: ${row.reorderLevel}'
                                        '${row.value != null ? ' · Value: ${row.value!.toStringAsFixed(2)}' : ''}',
                                      ),
                                      trailing: Text(
                                        '${row.quantity}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: row.isLowStock
                                              ? Colors.red.shade700
                                              : null,
                                        ),
                                      ),
                                      onTap: row.imeiTrackingEnabled
                                          ? null
                                          : () => Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    StockMovementHistoryScreen(
                                                      skuId: row.skuId,
                                                      displayName:
                                                          row.displayName,
                                                    ),
                                              ),
                                            ),
                                    ),
                                  const Divider(height: 1),
                                ],
                              ],
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

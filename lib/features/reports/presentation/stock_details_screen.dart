import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/reports_providers.dart';
import '../models/report_models.dart';
import 'stock_movement_history_screen.dart';

double? _totalValue(List<StockReportRow> rows) {
  if (rows.isEmpty || rows.any((r) => r.value == null)) return null;
  return rows.fold<double>(0, (sum, r) => sum + r.value!);
}

int _totalQuantity(List<StockReportRow> rows) => rows.fold<int>(0, (sum, r) => sum + r.quantity);

int _totalDemo(List<StockReportRow> rows) => rows.fold<int>(0, (sum, r) => sum + r.demoQuantity);

/// Base count text plus optional red "X low stock" / "Y demo" call-outs.
class _CountSubtitle extends StatelessWidget {
  const _CountSubtitle({required this.base, this.lowStockCount = 0, this.demoCount = 0});

  final String base;
  final int lowStockCount;
  final int demoCount;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          TextSpan(text: base),
          if (lowStockCount > 0)
            TextSpan(
              text: ' · $lowStockCount low stock',
              style: TextStyle(color: Colors.red.shade700),
            ),
          if (demoCount > 0)
            TextSpan(
              text: ' · $demoCount demo',
              style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}

class _QuantityBadge extends StatelessWidget {
  const _QuantityBadge({required this.quantity, required this.hasLowStock});

  final int quantity;
  final bool hasLowStock;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$quantity',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: hasLowStock ? Colors.red.shade700 : null,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right),
      ],
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.countLabel, required this.rows});

  final String countLabel;
  final List<StockReportRow> rows;

  @override
  Widget build(BuildContext context) {
    final totalValue = _totalValue(rows);
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(countLabel, style: Theme.of(context).textTheme.titleSmall),
          if (totalValue != null)
            Text(
              'Total value: ${totalValue.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}

/// Drill-down stock browser: Product Type -> Brand -> Model -> Color/SKU
/// (with full stock details), for when you know what you're looking for and
/// want to narrow straight down to it rather than scan one long list.
class StockDetailsScreen extends ConsumerWidget {
  const StockDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockAsync = ref.watch(stockDetailsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Current Stock Details')),
      body: stockAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load stock: $err')),
        data: (report) {
          final rows = report.rows;
          if (rows.isEmpty) {
            return const Center(child: Text('No stock to show.'));
          }

          final byType = <String, List<StockReportRow>>{};
          for (final row in rows) {
            byType.putIfAbsent(row.productType, () => []).add(row);
          }
          final types = byType.keys.toList()..sort();

          return Column(
            children: [
              _SummaryBar(countLabel: '${types.length} category(s) · ${rows.length} SKU(s)', rows: rows),
              Expanded(
                child: ListView.separated(
                  itemCount: types.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final type = types[index];
                    final typeRows = byType[type]!;
                    final lowStockCount = typeRows.where((r) => r.isLowStock).length;
                    return ListTile(
                      leading: const Icon(Icons.category_outlined),
                      title: Text(type),
                      subtitle: _CountSubtitle(
                        base: '${typeRows.length} SKU(s)',
                        lowStockCount: lowStockCount,
                        demoCount: _totalDemo(typeRows),
                      ),
                      trailing: _QuantityBadge(
                        quantity: _totalQuantity(typeRows),
                        hasLowStock: lowStockCount > 0,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _StockDetailsBrandsScreen(productType: type, rows: typeRows),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StockDetailsBrandsScreen extends StatelessWidget {
  const _StockDetailsBrandsScreen({required this.productType, required this.rows});

  final String productType;
  final List<StockReportRow> rows;

  @override
  Widget build(BuildContext context) {
    final byBrand = <String, List<StockReportRow>>{};
    for (final row in rows) {
      byBrand.putIfAbsent(row.brand, () => []).add(row);
    }
    final brands = byBrand.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: Text(productType)),
      body: Column(
        children: [
          _SummaryBar(countLabel: '${brands.length} brand(s) · ${rows.length} SKU(s)', rows: rows),
          Expanded(
            child: ListView.separated(
              itemCount: brands.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final brand = brands[index];
                final brandRows = byBrand[brand]!;
                final lowStockCount = brandRows.where((r) => r.isLowStock).length;
                return ListTile(
                  leading: const Icon(Icons.sell_outlined),
                  title: Text(brand),
                  subtitle: _CountSubtitle(
                    base: '${brandRows.length} SKU(s)',
                    lowStockCount: lowStockCount,
                    demoCount: _totalDemo(brandRows),
                  ),
                  trailing: _QuantityBadge(
                    quantity: _totalQuantity(brandRows),
                    hasLowStock: lowStockCount > 0,
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _StockDetailsModelsScreen(brand: brand, rows: brandRows),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StockDetailsModelsScreen extends StatelessWidget {
  const _StockDetailsModelsScreen({required this.brand, required this.rows});

  final String brand;
  final List<StockReportRow> rows;

  @override
  Widget build(BuildContext context) {
    final byModel = <String, List<StockReportRow>>{};
    for (final row in rows) {
      byModel.putIfAbsent(row.model, () => []).add(row);
    }
    final models = byModel.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: Text(brand)),
      body: Column(
        children: [
          _SummaryBar(countLabel: '${models.length} model(s) · ${rows.length} SKU(s)', rows: rows),
          Expanded(
            child: ListView.separated(
              itemCount: models.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final model = models[index];
                final modelRows = byModel[model]!;
                final lowStockCount = modelRows.where((r) => r.isLowStock).length;
                return ListTile(
                  leading: const Icon(Icons.phone_android_outlined),
                  title: Text(model),
                  subtitle: _CountSubtitle(
                    base: '${modelRows.length} color(s)',
                    lowStockCount: lowStockCount,
                    demoCount: _totalDemo(modelRows),
                  ),
                  trailing: _QuantityBadge(
                    quantity: _totalQuantity(modelRows),
                    hasLowStock: lowStockCount > 0,
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _StockDetailsColorsScreen(brand: brand, model: model, rows: modelRows),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StockDetailsColorsScreen extends StatelessWidget {
  const _StockDetailsColorsScreen({required this.brand, required this.model, required this.rows});

  final String brand;
  final String model;
  final List<StockReportRow> rows;

  @override
  Widget build(BuildContext context) {
    final byVariant = <String, List<StockReportRow>>{};
    for (final row in rows) {
      byVariant.putIfAbsent(row.variantLabel, () => []).add(row);
    }
    final variants = byVariant.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: Text('$brand $model')),
      body: Column(
        children: [
          _SummaryBar(countLabel: '${rows.length} color(s)', rows: rows),
          Expanded(
            child: ListView(
              children: [
                for (final variant in variants) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      variant.isEmpty ? 'Base variant' : variant,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  for (final row in (byVariant[variant]!..sort((a, b) => a.color.compareTo(b.color))))
                    Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            row.imeiTrackingEnabled
                                ? Icons.fingerprint
                                : Icons.inventory_2_outlined,
                          ),
                          title: Text(row.color),
                          subtitle: _CountSubtitle(
                            base: 'SKU: ${row.sku} · Reorder level: ${row.reorderLevel}'
                                '${row.value != null ? ' · Value: ${row.value!.toStringAsFixed(2)}' : ''}',
                            demoCount: row.demoQuantity,
                          ),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${row.quantity}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: row.isLowStock ? Colors.red.shade700 : null,
                                ),
                              ),
                              if (row.demoQuantity > 0)
                                Text(
                                  '${row.demoQuantity} demo',
                                  style: TextStyle(fontSize: 11, color: Colors.red.shade700),
                                ),
                            ],
                          ),
                          onTap: row.imeiTrackingEnabled
                              ? null
                              : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => StockMovementHistoryScreen(
                                        skuId: row.skuId,
                                        displayName: row.displayName,
                                      ),
                                    ),
                                  ),
                        ),
                        const Divider(height: 1),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

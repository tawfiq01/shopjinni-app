import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_state.dart';
import '../application/sales_providers.dart';
import '../data/sales_repository.dart';
import '../models/sale_models.dart';
import 'widgets/return_item_dialog.dart';

class SaleDetailScreen extends ConsumerStatefulWidget {
  const SaleDetailScreen({super.key, required this.invoiceId});
  final int invoiceId;

  @override
  ConsumerState<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends ConsumerState<SaleDetailScreen> {
  late Future<SalesInvoiceSummary> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(salesRepositoryProvider).getSale(widget.invoiceId);
  }

  void _reload() {
    setState(() {
      _future = ref.read(salesRepositoryProvider).getSale(widget.invoiceId);
    });
    ref.invalidate(salesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final canSell = ref.watch(authControllerProvider).user?.can('pos.sell') ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Sale Detail')),
      body: FutureBuilder<SalesInvoiceSummary>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load sale: ${snapshot.error}'));
          }
          final invoice = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(invoice.invoiceNumber, style: Theme.of(context).textTheme.titleLarge),
                      Text(invoice.customerName ?? 'Walk-in customer'),
                      Text(invoice.saleDate),
                      const Divider(height: 24),
                      Text('Total: ${invoice.total.toStringAsFixed(2)}'),
                      Text('Paid: ${invoice.paidAmount.toStringAsFixed(2)}'),
                      Text('Due: ${invoice.dueAmount.toStringAsFixed(2)}'),
                      if (invoice.profit != null) Text('Profit: ${invoice.profit!.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Items', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final item in invoice.items)
                Card(
                  child: ListTile(
                    title: Text(
                      item.isDemo ? '${item.displayName} · DEMO' : item.displayName,
                      style: TextStyle(
                        color: item.isDemo ? Colors.red.shade700 : null,
                        fontWeight: item.isDemo ? FontWeight.bold : null,
                      ),
                    ),
                    subtitle: Text(
                      '${item.quantity} × ${item.unitPrice.toStringAsFixed(2)} = ${item.lineTotal.toStringAsFixed(2)}'
                      '${item.imei != null ? ' · IMEI ${item.imei}' : ''}',
                    ),
                    trailing: canSell
                        ? TextButton(
                            onPressed: () async {
                              final done = await showReturnItemDialog(context, invoice, item);
                              if (done == true) _reload();
                            },
                            child: const Text('Return'),
                          )
                        : null,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

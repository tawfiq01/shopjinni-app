import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_state.dart';
import '../application/purchase_providers.dart';
import '../data/purchase_repository.dart';
import '../models/purchase_models.dart';
import 'widgets/return_purchase_item_dialog.dart';

class PurchaseDetailScreen extends ConsumerStatefulWidget {
  const PurchaseDetailScreen({super.key, required this.invoiceId});
  final int invoiceId;

  @override
  ConsumerState<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends ConsumerState<PurchaseDetailScreen> {
  late Future<PurchaseInvoice> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(purchaseRepositoryProvider).getPurchase(widget.invoiceId);
  }

  void _reload() {
    setState(() {
      _future = ref.read(purchaseRepositoryProvider).getPurchase(widget.invoiceId);
    });
    ref.invalidate(purchasesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final canManage = ref.watch(authControllerProvider).user?.can('purchases.manage') ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Detail')),
      body: FutureBuilder<PurchaseInvoice>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load purchase: ${snapshot.error}'));
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
                      Text(invoice.distributorName),
                      Text(invoice.purchaseDate),
                      const Divider(height: 24),
                      Text('Total: ${invoice.total.toStringAsFixed(2)}'),
                      Text('Paid: ${invoice.paidAmount.toStringAsFixed(2)}'),
                      Text('Due: ${invoice.dueAmount.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Items', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final item in invoice.items)
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(item.displayName),
                        subtitle: Text(
                          item.isImeiTracked
                              ? '${item.imeis.where((u) => u.isInStock).length} of ${item.quantity} still in stock'
                              : '${item.remainingQuantity} of ${item.quantity} still in stock',
                        ),
                        trailing: canManage
                            ? TextButton(
                                onPressed: () async {
                                  final done =
                                      await showReturnPurchaseItemDialog(context, invoice.id, item);
                                  if (done == true) _reload();
                                },
                                child: const Text('Return'),
                              )
                            : null,
                      ),
                      if (item.isImeiTracked)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final unit in item.imeis)
                                Chip(
                                  label: Text(
                                    unit.isDemo ? '${unit.imei1} · DEMO' : unit.imei1,
                                    style: TextStyle(
                                      color: unit.isDemo ? Colors.red.shade700 : null,
                                      fontWeight: unit.isDemo ? FontWeight.bold : null,
                                    ),
                                  ),
                                  backgroundColor: unit.isDemo ? Colors.red.shade50 : null,
                                ),
                            ],
                          ),
                        )
                      else if (item.demoQuantity > 0)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Text(
                            '${item.demoQuantity} of ${item.quantity} purchased as demo/display units',
                            style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

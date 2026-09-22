import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_state.dart';
import '../application/purchase_providers.dart';
import 'new_purchase_screen.dart';
import 'purchase_detail_screen.dart';

class PurchasesScreen extends ConsumerWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasesAsync = ref.watch(purchasesProvider);
    final canManage = ref.watch(authControllerProvider).user?.can('purchases.manage') ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Purchases')),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('New Purchase'),
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const NewPurchaseScreen()),
                );
                if (created == true) ref.invalidate(purchasesProvider);
              },
            )
          : null,
      body: purchasesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load purchases: $err')),
        data: (purchases) {
          if (purchases.isEmpty) {
            return const Center(child: Text('No purchases recorded yet.'));
          }
          return ListView.separated(
            itemCount: purchases.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final invoice = purchases[index];
              return ListTile(
                title: Text('${invoice.invoiceNumber} · ${invoice.distributorName}'),
                subtitle: Text('${invoice.purchaseDate} · ${invoice.items.length} item(s)'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(invoice.total.toStringAsFixed(2),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (invoice.dueAmount > 0)
                      Text('Due ${invoice.dueAmount.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                  ],
                ),
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => PurchaseDetailScreen(invoiceId: invoice.id),
                  ));
                  ref.invalidate(purchasesProvider);
                },
              );
            },
          );
        },
      ),
    );
  }
}

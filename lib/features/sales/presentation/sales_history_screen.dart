import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/sales_providers.dart';
import 'sale_detail_screen.dart';

class SalesHistoryScreen extends ConsumerWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sales History')),
      body: salesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load sales: $err')),
        data: (sales) {
          if (sales.isEmpty) {
            return const Center(child: Text('No sales recorded yet.'));
          }
          return ListView.separated(
            itemCount: sales.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final invoice = sales[index];
              return ListTile(
                title: Text('${invoice.invoiceNumber} · ${invoice.customerName ?? 'Walk-in'}'),
                subtitle: Text('${invoice.saleDate} · ${invoice.items.length} item(s)'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(invoice.total.toStringAsFixed(2),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (invoice.dueAmount > 0)
                      Text('Due ${invoice.dueAmount.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.red.shade700, fontSize: 12))
                    else if (invoice.profit != null)
                      Text('Profit ${invoice.profit!.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.green.shade700, fontSize: 12)),
                  ],
                ),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SaleDetailScreen(invoiceId: invoice.id),
                )),
              );
            },
          );
        },
      ),
    );
  }
}

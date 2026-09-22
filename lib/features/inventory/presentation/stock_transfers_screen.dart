import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_state.dart';
import '../application/stock_transfer_providers.dart';
import 'new_stock_transfer_screen.dart';

class StockTransfersScreen extends ConsumerWidget {
  const StockTransfersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfersAsync = ref.watch(stockTransfersProvider);
    final canTransfer = ref.watch(authControllerProvider).user?.can('stock.transfer') ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Stock Transfers')),
      floatingActionButton: canTransfer
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('New Transfer'),
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const NewStockTransferScreen()),
                );
                if (created == true) ref.invalidate(stockTransfersProvider);
              },
            )
          : null,
      body: transfersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load transfers: $err')),
        data: (transfers) {
          if (transfers.isEmpty) {
            return const Center(child: Text('No stock transfers yet.'));
          }
          return ListView.separated(
            itemCount: transfers.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final transfer = transfers[index];
              return ListTile(
                title: Text('${transfer.fromBranchName} → ${transfer.toBranchName}'),
                subtitle: Text('${transfer.transferDate} · ${transfer.items.length} item(s)'),
                trailing: Text('${transfer.items.fold(0, (sum, i) => sum + i.quantity)} unit(s)'),
              );
            },
          );
        },
      ),
    );
  }
}

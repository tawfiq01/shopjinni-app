import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/reports_providers.dart';

class CashPositionScreen extends ConsumerWidget {
  const CashPositionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashAsync = ref.watch(cashPositionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cash / Bank / MFS Position')),
      body: cashAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load cash position: $err')),
        data: (rows) {
          final total = rows.fold(0.0, (sum, r) => sum + r.balance);
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: Theme.of(context).textTheme.titleMedium),
                    Text(total.toStringAsFixed(2),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Divider(height: 1),
              for (final row in rows)
                ListTile(
                  title: Text(row.method),
                  subtitle: Text('Account ${row.accountCode}'),
                  trailing: Text(row.balance.toStringAsFixed(2)),
                ),
            ],
          );
        },
      ),
    );
  }
}

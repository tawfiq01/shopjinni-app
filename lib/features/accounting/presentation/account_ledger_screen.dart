import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/accounting_providers.dart';
import '../models/accounting_models.dart';

class AccountLedgerScreen extends ConsumerWidget {
  const AccountLedgerScreen({super.key, required this.account});

  final LedgerAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerAsync = ref.watch(accountLedgerProvider(account.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Balance: ${account.balance.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      body: ledgerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load ledger: $err')),
        data: (lines) {
          if (lines.isEmpty) {
            return const Center(child: Text('No entries yet.'));
          }
          return ListView.separated(
            itemCount: lines.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final line = lines[index];
              return ListTile(
                title: Text(line.narration),
                subtitle: Text(line.date),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      line.debit > 0 ? '+${line.debit.toStringAsFixed(2)}' : '-${line.credit.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: line.debit > 0 ? Colors.green.shade700 : Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Bal: ${line.runningBalance.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

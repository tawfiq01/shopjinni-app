import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_state.dart';
import '../application/accounting_providers.dart';
import '../models/accounting_models.dart';
import 'account_ledger_screen.dart';
import 'new_journal_entry_screen.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final canManage = ref.watch(authControllerProvider).user?.can('accounting.manage') ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Chart of Accounts')),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('New Entry'),
              onPressed: () async {
                final posted = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const NewJournalEntryScreen()),
                );
                if (posted == true) ref.invalidate(accountsProvider);
              },
            )
          : null,
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load accounts: $err')),
        data: (accounts) {
          final grouped = <String, List<LedgerAccount>>{};
          for (final account in accounts) {
            grouped.putIfAbsent(account.type, () => []).add(account);
          }

          return ListView(
            children: [
              for (final type in ['asset', 'liability', 'equity', 'income', 'expense'])
                if (grouped.containsKey(type)) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      _typeLabel(type),
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  for (final account in grouped[type]!)
                    ListTile(
                      title: Text(account.name),
                      subtitle: Text(account.code),
                      trailing: Text(
                        account.balance.toStringAsFixed(2),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => AccountLedgerScreen(account: account),
                      )),
                    ),
                ],
            ],
          );
        },
      ),
    );
  }

  String _typeLabel(String type) => switch (type) {
        'asset' => 'Assets',
        'liability' => 'Liabilities',
        'equity' => 'Equity',
        'income' => 'Income',
        'expense' => 'Expenses',
        _ => type,
      };
}

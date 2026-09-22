import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_state.dart';
import '../application/customer_providers.dart';
import '../models/customer.dart';
import 'customer_form_screen.dart';

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerAsync = ref.watch(customerLedgerProvider(customer.id));
    final canManage = ref.watch(authControllerProvider).user?.can('customers.manage') ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => CustomerFormScreen(customer: customer),
              )),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mobile: ${customer.mobile}'),
                  if (customer.address != null) Text('Address: ${customer.address}'),
                  if (customer.email != null) Text('Email: ${customer.email}'),
                  if (customer.creditLimit != null)
                    Text('Credit limit: ${customer.creditLimit!.toStringAsFixed(2)}'),
                  const Divider(height: 24),
                  Text(
                    customer.currentBalance == 0
                        ? 'Settled — no outstanding due'
                        : 'Outstanding due: ${customer.currentBalance.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: customer.currentBalance > 0
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Ledger', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ledgerAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Failed to load ledger: $err'),
            data: (lines) {
              if (lines.isEmpty) return const Text('No transactions yet.');
              return Column(
                children: [
                  for (final line in lines)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(line.narration),
                      subtitle: Text('${line.date} · ${line.account ?? ''}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            line.debit > 0
                                ? '+${line.debit.toStringAsFixed(2)}'
                                : '-${line.credit.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: line.debit > 0 ? Colors.red.shade700 : Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('Bal: ${line.runningBalance.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

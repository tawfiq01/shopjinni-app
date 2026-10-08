import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_state.dart';
import '../application/distributor_providers.dart';
import '../models/distributor.dart';
import 'distributor_form_screen.dart';
import 'widgets/pay_distributor_dialog.dart';

class DistributorDetailScreen extends ConsumerStatefulWidget {
  const DistributorDetailScreen({super.key, required this.distributor});

  final Distributor distributor;

  @override
  ConsumerState<DistributorDetailScreen> createState() => _DistributorDetailScreenState();
}

class _DistributorDetailScreenState extends ConsumerState<DistributorDetailScreen> {
  late Distributor _distributor = widget.distributor;

  Future<void> _pay() async {
    final updated = await showPayDistributorDialog(context, ref, _distributor);
    if (updated == null || !mounted) return;
    setState(() => _distributor = updated);
    ref.invalidate(distributorLedgerProvider(_distributor.id));
    ref.invalidate(distributorsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final distributor = _distributor;
    final ledgerAsync = ref.watch(distributorLedgerProvider(distributor.id));
    final canManage = ref.watch(authControllerProvider).user?.can('distributors.manage') ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(distributor.name),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => DistributorFormScreen(distributor: distributor),
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
                  if (distributor.companyName != null) Text(distributor.companyName!),
                  if (distributor.contactPerson != null) Text('Contact: ${distributor.contactPerson}'),
                  Text('Mobile: ${distributor.mobile}'),
                  if (distributor.altMobile != null) Text('Alt: ${distributor.altMobile}'),
                  if (distributor.address != null) Text('Address: ${distributor.address}'),
                  if (distributor.email != null) Text('Email: ${distributor.email}'),
                  if (distributor.paymentTerms != null) Text('Terms: ${distributor.paymentTerms}'),
                  if (distributor.creditLimit != null)
                    Text('Credit limit: ${distributor.creditLimit!.toStringAsFixed(2)}'),
                  const Divider(height: 24),
                  Text(
                    distributor.currentBalance == 0
                        ? 'Settled — no outstanding due'
                        : 'Outstanding due: ${distributor.currentBalance.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: distributor.currentBalance > 0
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (canManage && distributor.currentBalance > 0) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _pay,
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Pay Distributor'),
                    ),
                  ],
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
                            line.credit > 0
                                ? '+${line.credit.toStringAsFixed(2)}'
                                : '-${line.debit.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: line.credit > 0 ? Colors.red.shade700 : Colors.green.shade700,
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

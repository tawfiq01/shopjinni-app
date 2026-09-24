import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/admin_providers.dart';
import '../data/admin_repository.dart';
import '../models/admin_company.dart';
import '../models/admin_payment.dart';

class AdminPaymentsScreen extends ConsumerWidget {
  const AdminPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(adminPaymentsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog<void>(context: context, builder: (_) => const _RecordPaymentDialog()),
        icon: const Icon(Icons.add),
        label: const Text('Record payment'),
      ),
      body: paymentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load payments: $err')),
        data: (payments) => payments.isEmpty
            ? const Center(child: Text('No payments recorded yet.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: payments.length,
                itemBuilder: (context, index) => _PaymentTile(payment: payments[index]),
              ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});

  final AdminPayment payment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('${payment.companyName} — ৳${payment.amount.toStringAsFixed(0)}'),
        subtitle: Text(
          '${payment.planName} · ${payment.billingCycle} · ${payment.method}'
          '${payment.reference != null ? ' · ref ${payment.reference}' : ''}\n'
          '${payment.paidAt.toLocal()} · recorded by ${payment.recordedByName}',
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _RecordPaymentDialog extends ConsumerStatefulWidget {
  const _RecordPaymentDialog();

  @override
  ConsumerState<_RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends ConsumerState<_RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reference = TextEditingController();
  final _notes = TextEditingController();
  AdminCompany? _company;
  String _method = 'bkash';
  String _billingCycle = 'monthly';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _reference.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_company == null) {
      setState(() => _error = 'Choose a shop.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(adminRepositoryProvider).recordPayment(
            companyId: _company!.id,
            method: _method,
            billingCycle: _billingCycle,
            reference: _reference.text.trim().isEmpty ? null : _reference.text.trim(),
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          );
      ref.invalidate(adminPaymentsProvider);
      ref.invalidate(adminCompaniesProvider);
      if (mounted) Navigator.of(context).pop();
    } on AdminException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(adminCompaniesProvider);

    return AlertDialog(
      title: const Text('Record a payment'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              companiesAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (err, _) => Text('Failed to load shops: $err'),
                data: (companies) => DropdownButtonFormField<AdminCompany>(
                  initialValue: _company,
                  decoration: const InputDecoration(labelText: 'Shop'),
                  items: companies
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.name, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setState(() => _company = v),
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: const InputDecoration(labelText: 'Method'),
                items: const [
                  DropdownMenuItem(value: 'bkash', child: Text('bKash')),
                  DropdownMenuItem(value: 'nagad', child: Text('Nagad')),
                  DropdownMenuItem(value: 'bank', child: Text('Bank transfer')),
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _method = v ?? 'bkash'),
              ),
              DropdownButtonFormField<String>(
                initialValue: _billingCycle,
                decoration: const InputDecoration(labelText: 'Billing cycle'),
                items: const [
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                ],
                onChanged: (v) => setState(() => _billingCycle = v ?? 'monthly'),
              ),
              TextFormField(
                controller: _reference,
                decoration: const InputDecoration(labelText: 'Reference (transaction ID, optional)'),
              ),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
                maxLines: 2,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Record'),
        ),
      ],
    );
  }
}

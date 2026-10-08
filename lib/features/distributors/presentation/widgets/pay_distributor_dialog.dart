import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../purchasing/application/purchase_providers.dart';
import '../../../purchasing/models/purchase_models.dart';
import '../../data/distributor_repository.dart';
import '../../models/distributor.dart';

/// Returns the updated [Distributor] on a successful payment, or null if
/// the dialog was cancelled.
Future<Distributor?> showPayDistributorDialog(
  BuildContext context,
  WidgetRef ref,
  Distributor distributor,
) {
  return showDialog<Distributor>(
    context: context,
    builder: (context) => _PayDistributorDialog(distributor: distributor),
  );
}

class _PayDistributorDialog extends ConsumerStatefulWidget {
  const _PayDistributorDialog({required this.distributor});
  final Distributor distributor;

  @override
  ConsumerState<_PayDistributorDialog> createState() => _PayDistributorDialogState();
}

class _PayDistributorDialogState extends ConsumerState<_PayDistributorDialog> {
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  PaymentMethodOption? _method;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }
    if (amount > widget.distributor.currentBalance) {
      setState(() => _error = 'Amount cannot exceed the outstanding due.');
      return;
    }
    if (_method == null) {
      setState(() => _error = 'Select a payment method.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final updated = await ref.read(distributorRepositoryProvider).payDue(
            widget.distributor.id,
            paymentMethodId: _method!.id,
            amount: amount,
            referenceNo: _referenceController.text.trim().isEmpty
                ? null
                : _referenceController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(updated);
    } on DistributorException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);

    return AlertDialog(
      title: const Text('Pay Distributor'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.distributor.name} · Outstanding due: '
              '${widget.distributor.currentBalance.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount *'),
            ),
            const SizedBox(height: 12),
            paymentMethodsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => Text('Failed to load payment methods: $err'),
              data: (methods) {
                _method ??= methods.isNotEmpty ? methods.first : null;
                return DropdownButtonFormField<PaymentMethodOption>(
                  initialValue: _method,
                  decoration: const InputDecoration(labelText: 'Payment method *'),
                  items: methods
                      .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                      .toList(),
                  onChanged: (value) => setState(() => _method = value),
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _referenceController,
              decoration: const InputDecoration(labelText: 'Reference no. (optional)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Pay'),
        ),
      ],
    );
  }
}

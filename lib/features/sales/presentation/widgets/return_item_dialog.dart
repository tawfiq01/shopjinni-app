import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../purchasing/application/purchase_providers.dart';
import '../../../purchasing/models/purchase_models.dart';
import '../../data/sales_repository.dart';
import '../../models/sale_models.dart';

Future<bool?> showReturnItemDialog(
  BuildContext context,
  SalesInvoiceSummary invoice,
  SaleItemSummary item,
) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _ReturnItemDialog(invoice: invoice, item: item),
  );
}

class _ReturnItemDialog extends ConsumerStatefulWidget {
  const _ReturnItemDialog({required this.invoice, required this.item});
  final SalesInvoiceSummary invoice;
  final SaleItemSummary item;

  @override
  ConsumerState<_ReturnItemDialog> createState() => _ReturnItemDialogState();
}

class _ReturnItemDialogState extends ConsumerState<_ReturnItemDialog> {
  late final _quantityController = TextEditingController(
    text: widget.item.imei != null ? '1' : '1',
  );
  String _condition = 'returned';
  bool _restocked = true;
  PaymentMethodOption? _refundMethod;
  bool _submitting = false;
  String? _error;

  bool get _requiresRefundMethod => widget.invoice.customerId == null;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    if (quantity <= 0 || quantity > widget.item.quantity) {
      setState(() => _error = 'Enter a quantity between 1 and ${widget.item.quantity}.');
      return;
    }
    if (_requiresRefundMethod && _refundMethod == null) {
      setState(() => _error = 'A refund method is required — this sale has no customer to credit instead.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(salesRepositoryProvider).createSalesReturn(
            salesInvoiceId: widget.invoice.id,
            returnDate: DateTime.now().toIso8601String().split('T').first,
            saleItemId: widget.item.id,
            quantity: quantity,
            condition: _condition,
            restocked: _restocked,
            refundMethodId: _refundMethod?.id,
          );
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sales return recorded.')));
      }
    } on SalesException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);
    final isImei = widget.item.imei != null;

    return AlertDialog(
      title: Text('Return: ${widget.item.displayName}'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _quantityController,
              enabled: !isImei,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity (max ${widget.item.quantity})',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _condition,
              decoration: const InputDecoration(labelText: 'Condition'),
              items: const [
                DropdownMenuItem(value: 'returned', child: Text('Returned (good condition)')),
                DropdownMenuItem(value: 'damaged', child: Text('Damaged')),
              ],
              onChanged: (value) => setState(() {
                _condition = value!;
                if (_condition == 'damaged') _restocked = false;
              }),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Restock (make sellable again)'),
              value: _restocked,
              onChanged: _condition == 'damaged'
                  ? null
                  : (value) => setState(() => _restocked = value ?? false),
            ),
            paymentMethodsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => Text('Failed to load payment methods: $err'),
              data: (methods) => DropdownButtonFormField<PaymentMethodOption?>(
                initialValue: _refundMethod,
                decoration: InputDecoration(
                  labelText: _requiresRefundMethod
                      ? 'Refund method (required)'
                      : 'Refund method (optional — leave blank to credit customer account)',
                ),
                items: [
                  if (!_requiresRefundMethod)
                    const DropdownMenuItem<PaymentMethodOption?>(
                      value: null,
                      child: Text('Credit customer account'),
                    ),
                  ...methods.map((m) => DropdownMenuItem(value: m, child: Text(m.name))),
                ],
                onChanged: (value) => setState(() => _refundMethod = value),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Process Return'),
        ),
      ],
    );
  }
}

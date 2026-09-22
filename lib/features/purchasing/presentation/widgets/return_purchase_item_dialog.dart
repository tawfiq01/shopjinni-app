import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/purchase_repository.dart';
import '../../models/purchase_models.dart';

Future<bool?> showReturnPurchaseItemDialog(
  BuildContext context,
  int purchaseInvoiceId,
  PurchaseItemSummary item,
) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _ReturnPurchaseItemDialog(purchaseInvoiceId: purchaseInvoiceId, item: item),
  );
}

class _ReturnPurchaseItemDialog extends ConsumerStatefulWidget {
  const _ReturnPurchaseItemDialog({required this.purchaseInvoiceId, required this.item});
  final int purchaseInvoiceId;
  final PurchaseItemSummary item;

  @override
  ConsumerState<_ReturnPurchaseItemDialog> createState() => _ReturnPurchaseItemDialogState();
}

class _ReturnPurchaseItemDialogState extends ConsumerState<_ReturnPurchaseItemDialog> {
  final _quantityController = TextEditingController(text: '1');
  PurchasedImeiUnit? _selectedImei;
  bool _submitting = false;
  String? _error;

  List<PurchasedImeiUnit> get _availableImeis =>
      widget.item.imeis.where((u) => u.isInStock).toList();

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isImei = widget.item.isImeiTracked;
    if (isImei && _selectedImei == null) {
      setState(() => _error = 'Select which IMEI unit to return.');
      return;
    }

    final quantity = isImei ? 1 : (int.tryParse(_quantityController.text.trim()) ?? 0);
    if (!isImei && (quantity <= 0 || quantity > widget.item.remainingQuantity)) {
      setState(() => _error = 'Enter a quantity between 1 and ${widget.item.remainingQuantity}.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(purchaseRepositoryProvider).createPurchaseReturn(
            purchaseInvoiceId: widget.purchaseInvoiceId,
            returnDate: DateTime.now().toIso8601String().split('T').first,
            purchaseItemId: widget.item.id,
            quantity: quantity,
            imeiUnitId: _selectedImei?.id,
          );
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase return recorded.')));
      }
    } on PurchaseException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isImei = widget.item.isImeiTracked;

    return AlertDialog(
      title: Text('Return to distributor: ${widget.item.displayName}'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isImei)
              DropdownButtonFormField<PurchasedImeiUnit>(
                initialValue: _selectedImei,
                decoration: const InputDecoration(labelText: 'IMEI unit to return'),
                items: _availableImeis
                    .map((u) => DropdownMenuItem(value: u, child: Text(u.imei1)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedImei = value),
              )
            else
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity (max ${widget.item.remainingQuantity} in stock)',
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
              : const Text('Return'),
        ),
      ],
    );
  }
}

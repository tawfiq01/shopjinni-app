import 'package:flutter/material.dart';

import '../../../catalog/models/catalog_models.dart';
import '../../data/purchase_repository.dart';
import 'purchase_item_draft.dart';

class _ImeiRowControllers {
  _ImeiRowControllers()
      : imei1 = TextEditingController(),
        imei2 = TextEditingController(),
        serial = TextEditingController();
  final TextEditingController imei1;
  final TextEditingController imei2;
  final TextEditingController serial;
  bool isDemo = false;
}

Future<PurchaseItemDraft?> showConfigurePurchaseItemDialog(
  BuildContext context,
  CatalogProduct product,
) {
  return showDialog<PurchaseItemDraft>(
    context: context,
    builder: (context) => _ConfigurePurchaseItemDialog(product: product),
  );
}

class _ConfigurePurchaseItemDialog extends StatefulWidget {
  const _ConfigurePurchaseItemDialog({required this.product});
  final CatalogProduct product;

  @override
  State<_ConfigurePurchaseItemDialog> createState() => _ConfigurePurchaseItemDialogState();
}

class _ConfigurePurchaseItemDialogState extends State<_ConfigurePurchaseItemDialog> {
  final _quantityController = TextEditingController(text: '1');
  final _unitCostController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _taxController = TextEditingController(text: '0');
  final _warrantyController = TextEditingController(text: '12');
  List<_ImeiRowControllers> _imeiRows = [_ImeiRowControllers()];
  String? _error;

  int get _quantity => int.tryParse(_quantityController.text.trim()) ?? 0;

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_syncImeiRows);
  }

  void _syncImeiRows() {
    if (!widget.product.imeiTrackingEnabled) return;
    final target = _quantity.clamp(0, 200);
    setState(() {
      if (target > _imeiRows.length) {
        _imeiRows.addAll(List.generate(target - _imeiRows.length, (_) => _ImeiRowControllers()));
      } else if (target < _imeiRows.length) {
        _imeiRows = _imeiRows.sublist(0, target);
      }
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitCostController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    _warrantyController.dispose();
    super.dispose();
  }

  void _submit() {
    final quantity = _quantity;
    final unitCost = double.tryParse(_unitCostController.text.trim());

    if (quantity <= 0 || unitCost == null || unitCost < 0) {
      setState(() => _error = 'Enter a valid quantity and unit cost.');
      return;
    }

    var imeis = <ImeiEntry>[];
    if (widget.product.imeiTrackingEnabled) {
      imeis = _imeiRows
          .map((row) => ImeiEntry(
                imei1: row.imei1.text.trim(),
                imei2: row.imei2.text.trim().isEmpty ? null : row.imei2.text.trim(),
                serialNumber: row.serial.text.trim().isEmpty ? null : row.serial.text.trim(),
                isDemo: row.isDemo,
              ))
          .toList();
      if (imeis.any((e) => e.imei1.isEmpty)) {
        setState(() => _error = 'Every unit needs an IMEI 1.');
        return;
      }
    }

    Navigator.of(context).pop(PurchaseItemDraft(
      product: widget.product,
      quantity: quantity,
      unitCost: unitCost,
      discount: double.tryParse(_discountController.text.trim()) ?? 0,
      tax: double.tryParse(_taxController.text.trim()) ?? 0,
      warrantyMonths: int.tryParse(_warrantyController.text.trim()),
      imeis: imeis,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product.displayName),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _unitCostController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Unit purchase cost *'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _discountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Discount'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _taxController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Tax/VAT'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _warrantyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Warranty (months)'),
              ),
              if (widget.product.imeiTrackingEnabled) ...[
                const Divider(height: 24),
                Text('IMEI entry (${_imeiRows.length} unit(s))',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                for (var i = 0; i < _imeiRows.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _imeiRows[i].imei1,
                            decoration: InputDecoration(labelText: 'IMEI 1 · unit ${i + 1}'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _imeiRows[i].imei2,
                            decoration: const InputDecoration(labelText: 'IMEI 2'),
                          ),
                        ),
                        Checkbox(
                          value: _imeiRows[i].isDemo,
                          onChanged: (value) => setState(() => _imeiRows[i].isDemo = value ?? false),
                        ),
                        const Text('Demo', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
              ],
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
        FilledButton(onPressed: _submit, child: const Text('Add to Purchase')),
      ],
    );
  }
}

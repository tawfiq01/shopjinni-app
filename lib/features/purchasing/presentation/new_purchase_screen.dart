import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../distributors/application/distributor_providers.dart';
import '../../distributors/models/distributor.dart';
import '../application/purchase_providers.dart';
import '../data/purchase_repository.dart';
import '../models/purchase_models.dart';
import 'widgets/configure_purchase_item_dialog.dart';
import 'widgets/product_picker_dialog.dart';
import 'widgets/purchase_item_draft.dart';

class _PaymentDraft {
  _PaymentDraft({required this.method, required this.amountController});
  PaymentMethodOption method;
  final TextEditingController amountController;

  double get amount => double.tryParse(amountController.text.trim()) ?? 0;
}

class NewPurchaseScreen extends ConsumerStatefulWidget {
  const NewPurchaseScreen({super.key});

  @override
  ConsumerState<NewPurchaseScreen> createState() => _NewPurchaseScreenState();
}

class _NewPurchaseScreenState extends ConsumerState<NewPurchaseScreen> {
  Distributor? _distributor;
  DateTime _date = DateTime.now();
  final List<PurchaseItemDraft> _items = [];
  final List<_PaymentDraft> _payments = [];
  bool _submitting = false;
  String? _error;

  double get _total => _items.fold(0.0, (sum, item) => sum + item.lineTotal);
  double get _paid => _payments.fold(0.0, (sum, p) => sum + p.amount);

  Future<void> _addItem() async {
    final product = await showProductPickerDialog(context, ref);
    if (product == null || !mounted) return;
    final draft = await showConfigurePurchaseItemDialog(context, product);
    if (draft != null) setState(() => _items.add(draft));
  }

  Future<void> _addPayment() async {
    final methods = await ref.read(paymentMethodsProvider.future);
    if (methods.isEmpty || !mounted) return;
    setState(() => _payments.add(_PaymentDraft(
          method: methods.first,
          amountController: TextEditingController(),
        )));
  }

  Future<void> _submit() async {
    if (_distributor == null) {
      setState(() => _error = 'Select a distributor.');
      return;
    }
    if (_items.isEmpty) {
      setState(() => _error = 'Add at least one item.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(purchaseRepositoryProvider).createPurchase(
            distributorId: _distributor!.id,
            purchaseDate: _date.toIso8601String().split('T').first,
            items: _items.map((e) => e.toInput()).toList(),
            payments: _payments
                .where((p) => p.amount > 0)
                .map((p) => PurchasePaymentInput(paymentMethodId: p.method.id, amount: p.amount))
                .toList(),
          );
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase recorded.')));
      }
    } on PurchaseException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final distributorsAsync = ref.watch(distributorsProvider);
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Purchase')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          distributorsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (err, _) => Text('Failed to load distributors: $err'),
            data: (distributors) => DropdownButtonFormField<Distributor>(
              initialValue: _distributor,
              decoration: const InputDecoration(labelText: 'Distributor'),
              items: distributors
                  .map((d) => DropdownMenuItem(value: d, child: Text(d.name)))
                  .toList(),
              onChanged: (value) => setState(() => _distributor = value),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Purchase date'),
            subtitle: Text(_date.toIso8601String().split('T').first),
            trailing: const Icon(Icons.calendar_today, size: 18),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Items', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
                onPressed: _addItem,
              ),
            ],
          ),
          if (_items.isEmpty) const Text('No items added yet.'),
          for (var i = 0; i < _items.length; i++)
            Card(
              child: ListTile(
                title: Text(_items[i].product.displayName),
                subtitle: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${_items[i].quantity} × ${_items[i].unitCost.toStringAsFixed(2)} = '
                            '${_items[i].lineTotal.toStringAsFixed(2)}'
                            '${_items[i].imeis.isNotEmpty ? ' · ${_items[i].imeis.length} IMEI(s)' : ''}',
                      ),
                      if (_items[i].demoQuantity > 0)
                        TextSpan(
                          text: ' · ${_items[i].demoQuantity} demo',
                          style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _items.removeAt(i)),
                ),
              ),
            ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Payments', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Payment'),
                onPressed: _addPayment,
              ),
            ],
          ),
          paymentMethodsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (err, _) => Text('Failed to load payment methods: $err'),
            data: (methods) => Column(
              children: [
                for (var i = 0; i < _payments.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<PaymentMethodOption>(
                            initialValue: _payments[i].method,
                            decoration: const InputDecoration(labelText: 'Method'),
                            items: methods
                                .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _payments[i].method = value!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _payments[i].amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Amount'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => setState(() => _payments.removeAt(i)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total: ${_total.toStringAsFixed(2)}'),
              Text('Paid: ${_paid.toStringAsFixed(2)}'),
              Text('Due: ${(_total - _paid).toStringAsFixed(2)}'),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save Purchase'),
          ),
        ],
      ),
    );
  }
}

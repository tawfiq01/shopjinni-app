import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/models/catalog_models.dart';
import '../../customers/application/customer_providers.dart';
import '../../customers/models/customer.dart';
import '../../purchasing/application/purchase_providers.dart';
import '../../purchasing/models/purchase_models.dart';
import '../../purchasing/presentation/widgets/product_picker_dialog.dart';
import '../data/sales_repository.dart';
import '../models/sale_models.dart';

class PhoneExchangeScreen extends ConsumerStatefulWidget {
  const PhoneExchangeScreen({super.key});

  @override
  ConsumerState<PhoneExchangeScreen> createState() => _PhoneExchangeScreenState();
}

class _PhoneExchangeScreenState extends ConsumerState<PhoneExchangeScreen> {
  CatalogProduct? _oldPhone;
  final _oldImei1Controller = TextEditingController();
  final _oldImei2Controller = TextEditingController();
  final _exchangeValueController = TextEditingController();

  final _newPhoneSearchController = TextEditingController();
  List<PosCandidate> _newPhoneResults = [];
  PosCandidate? _newPhone;
  final _newPriceController = TextEditingController();

  Customer? _customer;
  PaymentMethodOption? _paymentMethod;
  final _paymentAmountController = TextEditingController();
  PaymentMethodOption? _refundMethod;

  bool _submitting = false;
  String? _error;

  double get _exchangeValue => double.tryParse(_exchangeValueController.text.trim()) ?? 0;
  double get _newPrice => double.tryParse(_newPriceController.text.trim()) ?? 0;
  double get _priceDifference => _newPrice - _exchangeValue;
  double get _paymentAmount => double.tryParse(_paymentAmountController.text.trim()) ?? 0;

  @override
  void dispose() {
    _oldImei1Controller.dispose();
    _oldImei2Controller.dispose();
    _exchangeValueController.dispose();
    _newPhoneSearchController.dispose();
    _newPriceController.dispose();
    _paymentAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickOldPhone() async {
    final product = await showProductPickerDialog(context, ref);
    if (product != null) setState(() => _oldPhone = product);
  }

  Future<void> _searchNewPhone(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _newPhoneResults = []);
      return;
    }
    try {
      final results = await ref.read(salesRepositoryProvider).search(query.trim());
      if (mounted) setState(() => _newPhoneResults = results);
    } on SalesException {
      // ignore transient errors, field stays usable
    }
  }

  void _selectNewPhone(PosCandidate candidate) {
    setState(() {
      _newPhone = candidate;
      _newPriceController.text = (candidate.sellingPriceCurrent ?? 0).toStringAsFixed(2);
      _newPhoneSearchController.clear();
      _newPhoneResults = [];
    });
  }

  Future<void> _submit() async {
    if (_oldPhone == null) {
      setState(() => _error = 'Select the old phone\'s catalog entry.');
      return;
    }
    if (_oldPhone!.imeiTrackingEnabled && _oldImei1Controller.text.trim().isEmpty) {
      setState(() => _error = 'Enter the old phone\'s IMEI.');
      return;
    }
    if (_newPhone == null) {
      setState(() => _error = 'Search and select the new phone being sold.');
      return;
    }
    if (_exchangeValue <= 0 || _newPrice <= 0) {
      setState(() => _error = 'Enter a valid exchange value and new phone price.');
      return;
    }
    if (_priceDifference < -0.005 && _refundMethod == null) {
      setState(() => _error = 'The old phone is worth more — pick a refund method.');
      return;
    }
    if (_priceDifference > 0.005 && _paymentAmount < _priceDifference - 0.005 && _customer == null) {
      setState(() => _error = 'Select a customer if the exchange won\'t be fully paid now.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await ref.read(salesRepositoryProvider).createPhoneExchange(
            customerId: _customer?.id,
            exchangeDate: DateTime.now().toIso8601String().split('T').first,
            oldProductVariantColorId: _oldPhone!.id,
            exchangeValue: _exchangeValue,
            oldImei1: _oldImei1Controller.text.trim().isEmpty ? null : _oldImei1Controller.text.trim(),
            oldImei2: _oldImei2Controller.text.trim().isEmpty ? null : _oldImei2Controller.text.trim(),
            newProductVariantColorId: _newPhone!.productVariantColorId,
            newImeiUnitId: _newPhone!.imeiUnitId,
            newUnitPrice: _newPrice,
            paymentMethodId: _priceDifference > 0.005 ? _paymentMethod?.id : null,
            paymentAmount: _priceDifference > 0.005 ? _paymentAmount : null,
            refundMethodId: _priceDifference < -0.005 ? _refundMethod?.id : null,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Exchange completed — sale ${result['sales_invoice']?['invoice_number'] ?? ''}'),
      ));
      Navigator.of(context).pop(true);
    } on SalesException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Phone Exchange')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Old phone (trade-in)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.search),
                    label: Text(_oldPhone?.displayName ?? 'Select catalog entry for old phone'),
                    onPressed: _pickOldPhone,
                  ),
                  if (_oldPhone != null && _oldPhone!.imeiTrackingEnabled) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _oldImei1Controller,
                      decoration: const InputDecoration(labelText: 'Old phone IMEI 1'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _oldImei2Controller,
                      decoration: const InputDecoration(labelText: 'Old phone IMEI 2 (optional)'),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextField(
                    controller: _exchangeValueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Exchange value (appraised)'),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('New phone (being sold)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_newPhone != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_newPhone!.displayName),
                      trailing: TextButton(
                        onPressed: () => setState(() => _newPhone = null),
                        child: const Text('Change'),
                      ),
                    )
                  else ...[
                    TextField(
                      controller: _newPhoneSearchController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search or scan IMEI for the new phone…',
                      ),
                      onChanged: _searchNewPhone,
                    ),
                    for (final candidate in _newPhoneResults)
                      ListTile(
                        title: Text(candidate.displayName),
                        onTap: () => _selectNewPhone(candidate),
                      ),
                  ],
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'New phone selling price'),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          customersAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (err, _) => Text('Failed to load customers: $err'),
            data: (customers) => DropdownButtonFormField<Customer?>(
              initialValue: _customer,
              decoration: const InputDecoration(labelText: 'Customer (optional)'),
              items: [
                const DropdownMenuItem<Customer?>(value: null, child: Text('Walk-in customer')),
                ...customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name))),
              ],
              onChanged: (value) => setState(() => _customer = value),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Price difference: ${_priceDifference.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    _priceDifference > 0
                        ? 'Customer pays the difference'
                        : _priceDifference < 0
                            ? 'Shop refunds the difference to the customer'
                            : 'Even exchange — nothing owed either way',
                  ),
                ],
              ),
            ),
          ),
          if (_priceDifference > 0.005) ...[
            const SizedBox(height: 16),
            paymentMethodsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => Text('Failed to load payment methods: $err'),
              data: (methods) => Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<PaymentMethodOption>(
                      initialValue: _paymentMethod,
                      decoration: const InputDecoration(labelText: 'Payment method'),
                      items: methods.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
                      onChanged: (value) => setState(() => _paymentMethod = value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _paymentAmountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Amount paid now'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_priceDifference < -0.005) ...[
            const SizedBox(height: 16),
            paymentMethodsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => Text('Failed to load payment methods: $err'),
              data: (methods) => DropdownButtonFormField<PaymentMethodOption>(
                initialValue: _refundMethod,
                decoration: const InputDecoration(labelText: 'Refund method'),
                items: methods.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
                onChanged: (value) => setState(() => _refundMethod = value),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Complete Exchange'),
          ),
        ],
      ),
    );
  }
}

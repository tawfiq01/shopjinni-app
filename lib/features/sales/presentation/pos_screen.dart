import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/barcode_scanner_sheet.dart';
import '../../customers/application/customer_providers.dart';
import '../../customers/models/customer.dart';
import '../../purchasing/application/purchase_providers.dart';
import '../../purchasing/models/purchase_models.dart';
import '../data/sales_repository.dart';
import '../models/sale_models.dart';
import 'phone_exchange_screen.dart';
import 'sales_history_screen.dart';
import 'widgets/cart_line.dart';

class _PaymentDraft {
  _PaymentDraft({required this.method, required this.amountController});
  PaymentMethodOption method;
  final TextEditingController amountController;

  double get amount => double.tryParse(amountController.text.trim()) ?? 0;
}

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchController = TextEditingController();
  List<PosCandidate> _results = [];
  bool _searching = false;
  final List<CartLine> _cart = [];
  final List<_PaymentDraft> _payments = [];
  Customer? _customer;
  bool _submitting = false;
  String? _error;

  double get _subtotal => _cart.fold(0.0, (sum, l) => sum + l.quantity.value * l.unitPrice);
  double get _discountTotal => _cart.fold(0.0, (sum, l) => sum + l.discount);
  double get _total => _subtotal - _discountTotal;
  double get _paid => _payments.fold(0.0, (sum, p) => sum + p.amount);
  double get _due => _total - _paid;

  @override
  void dispose() {
    _searchController.dispose();
    for (final line in _cart) {
      line.dispose();
    }
    for (final payment in _payments) {
      payment.amountController.dispose();
    }
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await ref.read(salesRepositoryProvider).search(query.trim());
      if (mounted) setState(() => _results = results);
    } on SalesException {
      // Ignore transient search errors; the field stays usable.
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  /// Optional shortcut for the search field: scans a barcode/IMEI via the
  /// camera and searches for it. Manual typing always still works too.
  Future<void> _scanAndSearch() async {
    final scanned = await showBarcodeScannerSheet(
      context,
      hintText: 'Point the camera at the barcode/IMEI',
    );
    if (scanned == null || !mounted) return;
    _searchController.text = scanned;
    await _search(scanned);
  }

  void _addToCart(PosCandidate candidate) {
    if (candidate.isImei &&
        _cart.any((l) => l.isImei && l.imeiUnitId == candidate.imeiUnitId)) {
      return; // already in cart
    }
    setState(() {
      if (!candidate.isImei) {
        final matchIndex = _cart.indexWhere(
          (l) => !l.isImei && l.productVariantColorId == candidate.productVariantColorId,
        );
        if (matchIndex != -1) {
          _cart[matchIndex].quantity.value++;
          _searchController.clear();
          _results = [];
          return;
        }
      }
      _cart.add(CartLine.fromCandidate(candidate));
      _searchController.clear();
      _results = [];
    });
  }

  void _removeFromCart(CartLine line) {
    setState(() {
      _cart.remove(line);
      line.dispose();
    });
  }

  Future<void> _addPayment() async {
    final methods = await ref.read(paymentMethodsProvider.future);
    if (methods.isEmpty || !mounted) return;
    setState(() => _payments.add(_PaymentDraft(
          method: methods.first,
          amountController: TextEditingController(text: _due > 0 ? _due.toStringAsFixed(2) : ''),
        )));
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) {
      setState(() => _error = 'Add at least one item.');
      return;
    }
    if (_due > 0.005 && _customer == null) {
      setState(() => _error = 'Select a customer for a due (partial/unpaid) sale.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final invoice = await ref.read(salesRepositoryProvider).createSale(
            customerId: _customer?.id,
            saleDate: DateTime.now().toIso8601String().split('T').first,
            items: _cart.map((l) => l.toInput()).toList(),
            payments: _payments
                .where((p) => p.amount > 0)
                .map((p) => SalePaymentInput(paymentMethodId: p.method.id, amount: p.amount))
                .toList(),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Sale ${invoice.invoiceNumber} completed — total ${invoice.total.toStringAsFixed(2)}'
          '${invoice.profit != null ? ' · profit ${invoice.profit!.toStringAsFixed(2)}' : ''}',
        ),
        duration: const Duration(seconds: 4),
      ));

      setState(() {
        for (final line in _cart) {
          line.dispose();
        }
        _cart.clear();
        for (final p in _payments) {
          p.amountController.dispose();
        }
        _payments.clear();
        _customer = null;
      });
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
      appBar: AppBar(
        title: const Text('POS / Sales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Phone exchange',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PhoneExchangeScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Sales history',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          final searchAndCart = _buildSearchAndCart();
          final checkoutPanel = _buildCheckoutPanel(customersAsync, paymentMethodsAsync);

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: searchAndCart),
                SizedBox(width: 360, child: checkoutPanel),
              ],
            );
          }
          return ListView(children: [searchAndCart, checkoutPanel]);
        },
      ),
    );
  }

  Widget _buildSearchAndCart() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search or scan IMEI, name, SKU, barcode…',
              border: const OutlineInputBorder(),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      tooltip: 'Scan barcode/IMEI',
                      onPressed: _scanAndSearch,
                    ),
            ),
            onChanged: _search,
            onSubmitted: _search,
          ),
          if (_results.isNotEmpty)
            Card(
              margin: const EdgeInsets.only(top: 4),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final candidate = _results[index];
                    return ListTile(
                      leading: Icon(
                        candidate.isImei ? Icons.fingerprint : Icons.inventory_2_outlined,
                        color: candidate.isDemo ? Colors.red.shade700 : null,
                      ),
                      title: Text(
                        candidate.isDemo ? '${candidate.displayName} · DEMO' : candidate.displayName,
                        style: TextStyle(
                          color: candidate.isDemo ? Colors.red.shade700 : null,
                          fontWeight: candidate.isDemo ? FontWeight.bold : null,
                        ),
                      ),
                      subtitle: candidate.isImei
                          ? const Text('Tap to add this exact unit')
                          : Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: 'Available: ${candidate.availableQuantity}'),
                                  if (candidate.demoQuantity > 0)
                                    TextSpan(
                                      text: ' · ${candidate.demoQuantity} demo',
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                      trailing: Text(candidate.sellingPriceCurrent?.toStringAsFixed(2) ?? '-'),
                      onTap: () => _addToCart(candidate),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text('Cart', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_cart.isEmpty) const Text('Cart is empty — search above to add items.'),
          for (final line in _cart) _buildCartRow(line),
        ],
      ),
    );
  }

  Widget _buildCartRow(CartLine line) {
    final nameText = line.isDemo
        ? Text(
            '${line.displayName} · DEMO',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red.shade700),
          )
        : Text.rich(
            TextSpan(
              style: const TextStyle(fontWeight: FontWeight.w500),
              children: [
                TextSpan(text: line.displayName),
                if (line.demoQuantity > 0)
                  TextSpan(
                    text: ' · ${line.demoQuantity} demo in stock',
                    style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          );

    final quantityControl = !line.isImei
        ? ValueListenableBuilder<int>(
            valueListenable: line.quantity,
            builder: (context, qty, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: qty > 1 ? () => setState(() => line.quantity.value--) : null,
                ),
                Text('$qty'),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => line.quantity.value++),
                ),
              ],
            ),
          )
        : const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('× 1'));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: nameText),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _removeFromCart(line),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                quantityControl,
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: line.unitPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Price', isDense: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: line.discountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Discount', isDense: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(line.lineTotal.toStringAsFixed(2), textAlign: TextAlign.right),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutPanel(
    AsyncValue<List<Customer>> customersAsync,
    AsyncValue<List<PaymentMethodOption>> paymentMethodsAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Payments', style: Theme.of(context).textTheme.titleSmall),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
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
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<PaymentMethodOption>(
                                initialValue: _payments[i].method,
                                isDense: true,
                                decoration: const InputDecoration(labelText: 'Method'),
                                items: methods
                                    .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                                    .toList(),
                                onChanged: (value) => setState(() => _payments[i].method = value!),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _payments[i].amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Amount', isDense: true),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => setState(() {
                                _payments[i].amountController.dispose();
                                _payments.removeAt(i);
                              }),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 32),
              _totalsRow('Subtotal', _subtotal),
              _totalsRow('Discount', _discountTotal),
              _totalsRow('Total', _total, bold: true),
              _totalsRow('Paid', _paid),
              _totalsRow('Due', _due, color: _due > 0 ? Colors.red.shade700 : Colors.green.shade700),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submitting ? null : _checkout,
                child: _submitting
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Complete Sale'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _totalsRow(String label, double value, {bool bold = false, Color? color}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value.toStringAsFixed(2), style: style),
        ],
      ),
    );
  }
}

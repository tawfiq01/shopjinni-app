import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../branches/application/branch_providers.dart';
import '../../branches/models/branch.dart';
import '../../sales/data/sales_repository.dart';
import '../../sales/models/sale_models.dart';
import '../data/stock_transfer_repository.dart';

class _TransferCartLine {
  _TransferCartLine({
    required this.productVariantColorId,
    required this.displayName,
    required this.isImei,
    this.imeiUnitId,
    this.imei1,
    // ignore: unused_element_parameter -- always starts at the default 1, mutated afterward.
    this.quantity = 1,
  });

  final int productVariantColorId;
  final String displayName;
  final bool isImei;
  final int? imeiUnitId;
  final String? imei1;
  int quantity;

  StockTransferItemInput toInput() => StockTransferItemInput(
        productVariantColorId: productVariantColorId,
        quantity: quantity,
        imeiUnitId: imeiUnitId,
      );
}

class NewStockTransferScreen extends ConsumerStatefulWidget {
  const NewStockTransferScreen({super.key});

  @override
  ConsumerState<NewStockTransferScreen> createState() => _NewStockTransferScreenState();
}

class _NewStockTransferScreenState extends ConsumerState<NewStockTransferScreen> {
  Branch? _fromBranch;
  Branch? _toBranch;
  DateTime _date = DateTime.now();
  final _searchController = TextEditingController();
  List<PosCandidate> _results = [];
  final List<_TransferCartLine> _cart = [];
  final _notesController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (_fromBranch == null || query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    try {
      final results = await ref
          .read(salesRepositoryProvider)
          .search(query.trim(), branchId: _fromBranch!.id);
      if (mounted) setState(() => _results = results);
    } on SalesException {
      // ignore transient errors
    }
  }

  void _addToCart(PosCandidate candidate) {
    if (candidate.isImei && _cart.any((l) => l.imeiUnitId == candidate.imeiUnitId)) return;

    setState(() {
      if (!candidate.isImei) {
        final index = _cart.indexWhere(
          (l) => !l.isImei && l.productVariantColorId == candidate.productVariantColorId,
        );
        if (index != -1) {
          _cart[index].quantity++;
          _searchController.clear();
          _results = [];
          return;
        }
      }
      _cart.add(_TransferCartLine(
        productVariantColorId: candidate.productVariantColorId,
        displayName: candidate.displayName,
        isImei: candidate.isImei,
        imeiUnitId: candidate.imeiUnitId,
        imei1: candidate.imei1,
      ));
      _searchController.clear();
      _results = [];
    });
  }

  Future<void> _submit() async {
    if (_fromBranch == null || _toBranch == null) {
      setState(() => _error = 'Select both the source and destination branch.');
      return;
    }
    if (_fromBranch!.id == _toBranch!.id) {
      setState(() => _error = 'Source and destination branch must be different.');
      return;
    }
    if (_cart.isEmpty) {
      setState(() => _error = 'Add at least one item to transfer.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(stockTransferRepositoryProvider).createTransfer(
            fromBranchId: _fromBranch!.id,
            toBranchId: _toBranch!.id,
            transferDate: _date.toIso8601String().split('T').first,
            items: _cart.map((l) => l.toInput()).toList(),
            notes: _notesController.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock transfer recorded.')));
      }
    } on StockTransferException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Stock Transfer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          branchesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (err, _) => Text('Failed to load branches: $err'),
            data: (branches) => Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Branch>(
                    initialValue: _fromBranch,
                    decoration: const InputDecoration(labelText: 'From branch'),
                    items: branches.map((b) => DropdownMenuItem(value: b, child: Text(b.name))).toList(),
                    onChanged: (value) => setState(() {
                      _fromBranch = value;
                      _cart.clear();
                      _results = [];
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<Branch>(
                    initialValue: _toBranch,
                    decoration: const InputDecoration(labelText: 'To branch'),
                    items: branches.map((b) => DropdownMenuItem(value: b, child: Text(b.name))).toList(),
                    onChanged: (value) => setState(() => _toBranch = value),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Transfer date'),
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
          const Divider(height: 24),
          TextField(
            controller: _searchController,
            enabled: _fromBranch != null,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: _fromBranch == null
                  ? 'Pick the source branch first…'
                  : 'Search stock at ${_fromBranch!.name}…',
              border: const OutlineInputBorder(),
            ),
            onChanged: _search,
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
                      leading: Icon(candidate.isImei ? Icons.fingerprint : Icons.inventory_2_outlined),
                      title: Text(candidate.displayName),
                      subtitle: candidate.isImei
                          ? null
                          : Text('Available: ${candidate.availableQuantity}'),
                      onTap: () => _addToCart(candidate),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text('Items to transfer', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_cart.isEmpty) const Text('No items added yet.'),
          for (var i = 0; i < _cart.length; i++)
            Card(
              child: ListTile(
                title: Text(_cart[i].displayName),
                subtitle: _cart[i].isImei ? const Text('1 unit (IMEI)') : null,
                trailing: _cart[i].isImei
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => setState(() => _cart.removeAt(i)),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _cart[i].quantity > 1
                                ? () => setState(() => _cart[i].quantity--)
                                : null,
                          ),
                          Text('${_cart[i].quantity}'),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setState(() => _cart[i].quantity++),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => setState(() => _cart.removeAt(i)),
                          ),
                        ],
                      ),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
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
                : const Text('Transfer Stock'),
          ),
        ],
      ),
    );
  }
}

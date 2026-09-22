import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reports_repository.dart';
import '../models/report_models.dart';

class ImeiHistoryScreen extends ConsumerStatefulWidget {
  const ImeiHistoryScreen({super.key});

  @override
  ConsumerState<ImeiHistoryScreen> createState() => _ImeiHistoryScreenState();
}

class _ImeiHistoryScreenState extends ConsumerState<ImeiHistoryScreen> {
  final _searchController = TextEditingController();
  bool _searching = false;
  ImeiHistory? _history;
  String? _error;
  bool _searched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final imei = _searchController.text.trim();
    if (imei.isEmpty) return;

    setState(() {
      _searching = true;
      _error = null;
      _searched = true;
    });

    try {
      final history = await ref.read(reportsRepositoryProvider).getImeiHistory(imei);
      if (mounted) setState(() => _history = history);
    } on ReportsException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  IconData _iconFor(String type) => switch (type) {
        'purchase' => Icons.add_shopping_cart_outlined,
        'sale' => Icons.point_of_sale_outlined,
        'sales_return' => Icons.assignment_return_outlined,
        'purchase_return' => Icons.local_shipping_outlined,
        'transfer_out' || 'transfer_in' => Icons.compare_arrows,
        _ => Icons.circle_outlined,
      };

  String _labelFor(String type) => switch (type) {
        'purchase' => 'Purchased',
        'sale' => 'Sold',
        'sales_return' => 'Returned by customer',
        'purchase_return' => 'Returned to distributor',
        'transfer_out' => 'Transferred out',
        'transfer_in' => 'Transferred in',
        _ => type,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('IMEI History')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Enter or scan an IMEI…',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _searching ? null : _search,
              child: _searching
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Search'),
            ),
            const SizedBox(height: 16),
            if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            if (_searched && _history == null && _error == null && !_searching)
              const Text('No unit found with that IMEI.'),
            if (_history != null) Expanded(child: _buildHistory(_history!)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory(ImeiHistory history) {
    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  history.isDemo ? '${history.displayName} · DEMO DEVICE' : history.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: history.isDemo ? Colors.red.shade700 : null,
                        fontWeight: history.isDemo ? FontWeight.bold : null,
                      ),
                ),
                Text('IMEI 1: ${history.imei1}'),
                if (history.imei2 != null) Text('IMEI 2: ${history.imei2}'),
                Text('Status: ${history.status}'),
                Text('Distributor: ${history.distributor}'),
                if (history.purchasedAt != null) Text('Purchased: ${history.purchasedAt}'),
                if (history.soldAt != null) Text('Sold: ${history.soldAt}'),
                if (history.purchaseCost != null)
                  Text('Purchase cost: ${history.purchaseCost!.toStringAsFixed(2)}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Timeline', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final movement in history.movements)
          ListTile(
            leading: Icon(_iconFor(movement.type)),
            title: Text(_labelFor(movement.type)),
            subtitle: Text('${movement.date} · ${movement.branch}'),
            trailing: movement.unitCost != null ? Text(movement.unitCost!.toStringAsFixed(2)) : null,
          ),
      ],
    );
  }
}

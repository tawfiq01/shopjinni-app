import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../catalog/data/catalog_repository.dart';
import '../../../catalog/models/catalog_models.dart';

Future<CatalogProduct?> showProductPickerDialog(BuildContext context, WidgetRef ref) {
  return showDialog<CatalogProduct>(
    context: context,
    builder: (context) => const _ProductPickerDialog(),
  );
}

class _ProductPickerDialog extends ConsumerStatefulWidget {
  const _ProductPickerDialog();

  @override
  ConsumerState<_ProductPickerDialog> createState() => _ProductPickerDialogState();
}

class _ProductPickerDialogState extends ConsumerState<_ProductPickerDialog> {
  List<CatalogProduct> _results = [];
  bool _loading = false;
  String _query = '';

  Future<void> _search(String query) async {
    setState(() {
      _query = query;
      _loading = true;
    });
    try {
      final results = await ref.read(catalogRepositoryProvider).searchProducts(query);
      if (mounted && _query == query) {
        setState(() {
          _results = results;
          _loading = false;
        });
      }
    } on CatalogException {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Product'),
      content: SizedBox(
        width: 420,
        height: 420,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by name, SKU, barcode…',
              ),
              onChanged: _search,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? const Center(child: Text('No products found.'))
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final product = _results[index];
                            return ListTile(
                              title: Text(product.displayName),
                              subtitle: Text(
                                product.imeiTrackingEnabled ? 'IMEI tracked' : 'Quantity tracked',
                              ),
                              onTap: () => Navigator.of(context).pop(product),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
      ],
    );
  }
}

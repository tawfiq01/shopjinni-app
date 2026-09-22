import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/catalog_providers.dart';
import '../../data/catalog_repository.dart';
import '../../models/catalog_models.dart';

void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
  );
}

void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<String?> promptForText(
  BuildContext context, {
  required String title,
  required String label,
  String? initialValue,
}) {
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(labelText: label),
        onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

Future<(String, String?)?> promptForColor(
  BuildContext context, {
  String? initialName,
  String? initialHex,
}) {
  final nameController = TextEditingController(text: initialName);
  final hexController = TextEditingController(text: initialHex);
  return showDialog<(String, String?)>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(initialName == null ? 'New Color' : 'Edit Color'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Color name (e.g. Midnight Black)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: hexController,
            decoration: const InputDecoration(
              labelText: 'Hex code (optional)',
              hintText: '#000000',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop((
            nameController.text.trim(),
            hexController.text.trim().isEmpty ? null : hexController.text.trim(),
          )),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

Future<void> showAddModelDialog(BuildContext context, WidgetRef ref) =>
    _showModelFormDialog(context, ref, existing: null);

Future<void> showEditModelDialog(BuildContext context, WidgetRef ref, CatalogModel model) =>
    _showModelFormDialog(context, ref, existing: model);

Future<void> _showModelFormDialog(
  BuildContext context,
  WidgetRef ref, {
  required CatalogModel? existing,
}) async {
  final brands = await ref.read(brandsProvider.future);
  final types = await ref.read(productTypesProvider.future);

  if (!context.mounted) return;

  if (brands.isEmpty || types.isEmpty) {
    showErrorSnackBar(context, 'Add at least one brand and product type first.');
    return;
  }

  final nameController = TextEditingController(text: existing?.name);
  final warrantyController = TextEditingController(
    text: (existing?.warrantyMonthsDefault ?? 12).toString(),
  );
  Brand? selectedBrand = existing == null
      ? brands.first
      : brands.firstWhere((b) => b.id == existing.brand.id, orElse: () => brands.first);
  ProductType? selectedType = existing == null
      ? types.first
      : types.firstWhere((t) => t.id == existing.productType.id, orElse: () => types.first);
  bool? imeiOverride = existing?.imeiTrackingEnabled; // null = inherit from product type

  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(existing == null ? 'New Model' : 'Edit Model'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<Brand>(
                initialValue: selectedBrand,
                decoration: const InputDecoration(labelText: 'Brand'),
                items: brands
                    .map((b) => DropdownMenuItem(value: b, child: Text(b.name)))
                    .toList(),
                onChanged: (value) => setState(() => selectedBrand = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ProductType>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Product Type'),
                items: types
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                    .toList(),
                onChanged: (value) => setState(() => selectedType = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Model name (e.g. Galaxy A25)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: warrantyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Warranty (months)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<bool?>(
                initialValue: imeiOverride,
                decoration: const InputDecoration(labelText: 'IMEI tracking'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Inherit from product type')),
                  DropdownMenuItem(value: true, child: Text('Always required')),
                  DropdownMenuItem(value: false, child: Text('Never')),
                ],
                onChanged: (value) => setState(() => imeiOverride = value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(existing == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    ),
  );

  if (saved != true || !context.mounted) return;
  if (nameController.text.trim().isEmpty) return;

  try {
    if (existing == null) {
      await ref.read(catalogRepositoryProvider).createModel(
            brandId: selectedBrand!.id,
            productTypeId: selectedType!.id,
            name: nameController.text.trim(),
            warrantyMonthsDefault: int.tryParse(warrantyController.text.trim()),
            imeiTrackingEnabled: imeiOverride,
          );
    } else {
      await ref.read(catalogRepositoryProvider).updateModel(
            existing.id,
            brandId: selectedBrand!.id,
            productTypeId: selectedType!.id,
            name: nameController.text.trim(),
            warrantyMonthsDefault: int.tryParse(warrantyController.text.trim()),
            imeiTrackingEnabled: imeiOverride,
          );
    }
    ref.invalidate(modelsProvider);
    if (existing != null) ref.invalidate(modelDetailProvider(existing.id));
    if (context.mounted) {
      showSuccessSnackBar(context, existing == null ? 'Model created.' : 'Model updated.');
    }
  } on CatalogException catch (e) {
    if (context.mounted) showErrorSnackBar(context, e.message);
  }
}

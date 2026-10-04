import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/catalog_providers.dart';
import '../data/catalog_repository.dart';
import '../models/catalog_models.dart';
import 'widgets/catalog_dialogs.dart';

class ModelDetailScreen extends ConsumerWidget {
  const ModelDetailScreen({super.key, required this.modelId});

  final int modelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelAsync = ref.watch(modelDetailProvider(modelId));
    final loadedModel = modelAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Model Details'),
        actions: [
          if (loadedModel != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit model',
              onPressed: () => showEditModelDialog(context, ref, loadedModel),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Variant'),
        onPressed: () => _showAddVariantDialog(context, ref),
      ),
      body: modelAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load: $err')),
        data: (model) => _ModelDetailBody(model: model),
      ),
    );
  }

  Future<void> _showAddVariantDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ramController = TextEditingController();
    final storageController = TextEditingController();
    final extraController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Variant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ramController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'RAM (e.g. 8GB)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: storageController,
              decoration: const InputDecoration(
                labelText: 'Storage (e.g. 128GB)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: extraController,
              decoration: const InputDecoration(
                labelText: 'Extra spec (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (created != true || !context.mounted) return;

    try {
      await ref
          .read(catalogRepositoryProvider)
          .createVariant(
            modelId: modelId,
            ram: ramController.text.trim(),
            storage: storageController.text.trim(),
            extraSpec: extraController.text.trim(),
          );
      ref.invalidate(modelDetailProvider(modelId));
      if (context.mounted) showSuccessSnackBar(context, 'Variant created.');
    } on CatalogException catch (e) {
      if (context.mounted) showErrorSnackBar(context, e.message);
    }
  }
}

class _ModelDetailBody extends ConsumerWidget {
  const _ModelDetailBody({required this.model});

  final CatalogModel model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${model.brand.name} ${model.name}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '${model.productType.name} · Warranty: ${model.warrantyMonthsDefault ?? '-'} months',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Variants', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (model.variants.isEmpty)
          const Text('No variants yet. Use "Add Variant" below.'),
        for (final variant in model.variants)
          _VariantCard(model: model, variant: variant),
      ],
    );
  }
}

class _VariantCard extends ConsumerWidget {
  const _VariantCard({required this.model, required this.variant});

  final CatalogModel model;
  final ProductVariant variant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    variant.label.isEmpty ? 'Base variant' : variant.label,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit variant',
                  onPressed: () => _showEditVariantDialog(context, ref),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Color / SKU'),
                  onPressed: () => _showAddSkuDialog(context, ref),
                ),
              ],
            ),
            if (variant.colors.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('No colors/SKUs yet.'),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final sku in variant.colors)
                    InputChip(
                      avatar: sku.imeiTrackingEnabled
                          ? const Icon(Icons.fingerprint, size: 16)
                          : const Icon(Icons.inventory_2_outlined, size: 16),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${sku.color.name} · ${sku.sku}'),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit_outlined, size: 14),
                        ],
                      ),
                      tooltip: 'Edit ${sku.color.name} SKU',
                      onPressed: () => _showEditSkuDialog(context, ref, sku),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddSkuDialog(BuildContext context, WidgetRef ref) async {
    final colors = await ref.read(colorsProvider.future);
    if (!context.mounted) return;
    if (colors.isEmpty) {
      showErrorSnackBar(context, 'Add at least one color first (Colors tab).');
      return;
    }

    ProductColor selectedColor = colors.first;
    final skuController = TextEditingController();
    final barcodeController = TextEditingController();
    final reorderController = TextEditingController(text: '0');
    final priceController = TextEditingController();
    bool? imeiOverride;

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Color / SKU'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<ProductColor>(
                  initialValue: selectedColor,
                  decoration: const InputDecoration(labelText: 'Color'),
                  items: colors
                      .map(
                        (c) => DropdownMenuItem(value: c, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => selectedColor = value!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: skuController,
                  decoration: const InputDecoration(
                    labelText: 'SKU (optional — auto-generated if blank)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Barcode (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reorderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Reorder level'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Selling price / MRP (optional)',
                    prefixText: '৳ ',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<bool?>(
                  initialValue: imeiOverride,
                  decoration: const InputDecoration(labelText: 'IMEI tracking'),
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('Inherit from model'),
                    ),
                    DropdownMenuItem(value: true, child: Text('Required')),
                    DropdownMenuItem(value: false, child: Text('Not required')),
                  ],
                  onChanged: (value) => setState(() => imeiOverride = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (created != true || !context.mounted) return;

    try {
      await ref
          .read(catalogRepositoryProvider)
          .createSku(
            variantId: variant.id,
            colorId: selectedColor.id,
            sku: skuController.text.trim(),
            barcode: barcodeController.text.trim(),
            reorderLevel: int.tryParse(reorderController.text.trim()),
            sellingPriceCurrent: double.tryParse(priceController.text.trim()),
            imeiTrackingEnabled: imeiOverride,
          );
      ref.invalidate(modelDetailProvider(model.id));
      if (context.mounted) showSuccessSnackBar(context, 'Color / SKU created.');
    } on CatalogException catch (e) {
      if (context.mounted) showErrorSnackBar(context, e.message);
    }
  }

  Future<void> _showEditVariantDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ramController = TextEditingController(text: variant.ram);
    final storageController = TextEditingController(text: variant.storage);
    final extraController = TextEditingController(text: variant.extraSpec);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Variant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ramController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'RAM (e.g. 8GB)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: storageController,
              decoration: const InputDecoration(
                labelText: 'Storage (e.g. 128GB)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: extraController,
              decoration: const InputDecoration(
                labelText: 'Extra spec (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true || !context.mounted) return;

    try {
      await ref
          .read(catalogRepositoryProvider)
          .updateVariant(
            variant.id,
            ram: ramController.text.trim(),
            storage: storageController.text.trim(),
            extraSpec: extraController.text.trim(),
          );
      ref.invalidate(modelDetailProvider(model.id));
      if (context.mounted) showSuccessSnackBar(context, 'Variant updated.');
    } on CatalogException catch (e) {
      if (context.mounted) showErrorSnackBar(context, e.message);
    }
  }

  Future<void> _showEditSkuDialog(
    BuildContext context,
    WidgetRef ref,
    ProductSku sku,
  ) async {
    final colors = await ref.read(colorsProvider.future);
    if (!context.mounted) return;
    if (!colors.any((color) => color.id == sku.color.id)) {
      colors.insert(0, sku.color);
    }

    ProductColor selectedColor = colors.firstWhere(
      (color) => color.id == sku.color.id,
    );
    final skuController = TextEditingController(text: sku.sku);
    final barcodeController = TextEditingController(text: sku.barcode);
    final reorderController = TextEditingController(
      text: sku.reorderLevel.toString(),
    );
    final priceController = TextEditingController(
      text: sku.sellingPriceCurrent?.toStringAsFixed(2) ?? '',
    );
    bool? imeiOverride = sku.imeiTrackingOverride;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit ${sku.color.name} SKU'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<ProductColor>(
                  initialValue: selectedColor,
                  decoration: const InputDecoration(labelText: 'Color'),
                  items: colors
                      .map(
                        (color) => DropdownMenuItem(
                          value: color,
                          child: Text(color.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => selectedColor = value!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: skuController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'SKU'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Barcode (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reorderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Reorder level'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Selling price / MRP (optional)',
                    prefixText: '৳ ',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<bool?>(
                  initialValue: imeiOverride,
                  decoration: const InputDecoration(labelText: 'IMEI tracking'),
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('Inherit from model'),
                    ),
                    DropdownMenuItem(value: true, child: Text('Required')),
                    DropdownMenuItem(value: false, child: Text('Not required')),
                  ],
                  onChanged: (value) => setState(() => imeiOverride = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !context.mounted) return;

    try {
      await ref
          .read(catalogRepositoryProvider)
          .updateSku(
            sku.id,
            sku: skuController.text.trim(),
            colorId: selectedColor.id,
            barcode: barcodeController.text.trim(),
            reorderLevel: int.tryParse(reorderController.text.trim()),
            sellingPriceCurrent: double.tryParse(priceController.text.trim()),
            imeiTrackingEnabled: imeiOverride,
          );
      ref.invalidate(modelDetailProvider(model.id));
      if (context.mounted) showSuccessSnackBar(context, 'SKU updated.');
    } on CatalogException catch (e) {
      if (context.mounted) showErrorSnackBar(context, e.message);
    }
  }
}

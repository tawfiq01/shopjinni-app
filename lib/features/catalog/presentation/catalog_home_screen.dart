import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/catalog_providers.dart';
import '../data/catalog_repository.dart';
import 'model_detail_screen.dart';
import 'widgets/catalog_dialogs.dart';

class CatalogHomeScreen extends StatelessWidget {
  const CatalogHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Catalog'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Models'),
            Tab(text: 'Brands'),
            Tab(text: 'Colors'),
          ]),
        ),
        body: const TabBarView(children: [
          _ModelsTab(),
          _BrandsTab(),
          _ColorsTab(),
        ]),
      ),
    );
  }
}

class _ModelsTab extends ConsumerWidget {
  const _ModelsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelsAsync = ref.watch(modelsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Model'),
        onPressed: () => showAddModelDialog(context, ref),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search models…',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => ref.read(modelSearchProvider.notifier).set(value),
            ),
          ),
          Expanded(
            child: modelsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Failed to load models: $err')),
              data: (models) {
                if (models.isEmpty) {
                  return const Center(child: Text('No models yet. Add one to get started.'));
                }
                return ListView.separated(
                  itemCount: models.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final model = models[index];
                    return ListTile(
                      title: Text('${model.brand.name} ${model.name}'),
                      subtitle: Text(
                        '${model.productType.name} · ${model.variants.length} variant(s)',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ModelDetailScreen(modelId: model.id),
                      )),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandsTab extends ConsumerWidget {
  const _BrandsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsAsync = ref.watch(brandsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Brand'),
        onPressed: () async {
          final name = await promptForText(context, title: 'New Brand', label: 'Brand name');
          if (name == null || name.isEmpty) return;
          try {
            await ref.read(catalogRepositoryProvider).createBrand(name);
            ref.invalidate(brandsProvider);
            if (context.mounted) showSuccessSnackBar(context, 'Brand created.');
          } on CatalogException catch (e) {
            if (context.mounted) showErrorSnackBar(context, e.message);
          }
        },
      ),
      body: brandsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load brands: $err')),
        data: (brands) {
          if (brands.isEmpty) {
            return const Center(child: Text('No brands yet. Add one to get started.'));
          }
          return ListView.separated(
            itemCount: brands.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final brand = brands[index];
              return ListTile(
                title: Text(brand.name),
                subtitle: brand.isActive ? null : const Text('Inactive'),
                trailing: const Icon(Icons.edit_outlined, size: 20),
                onTap: () async {
                  final name = await promptForText(
                    context,
                    title: 'Edit Brand',
                    label: 'Brand name',
                    initialValue: brand.name,
                  );
                  if (name == null || name.isEmpty || name == brand.name) return;
                  try {
                    await ref.read(catalogRepositoryProvider).updateBrand(brand.id, name: name);
                    ref.invalidate(brandsProvider);
                    if (context.mounted) showSuccessSnackBar(context, 'Brand updated.');
                  } on CatalogException catch (e) {
                    if (context.mounted) showErrorSnackBar(context, e.message);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ColorsTab extends ConsumerWidget {
  const _ColorsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorsAsync = ref.watch(colorsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Color'),
        onPressed: () async {
          final result = await promptForColor(context);
          if (result == null) return;
          try {
            await ref.read(catalogRepositoryProvider).createColor(result.$1, result.$2);
            ref.invalidate(colorsProvider);
            if (context.mounted) showSuccessSnackBar(context, 'Color created.');
          } on CatalogException catch (e) {
            if (context.mounted) showErrorSnackBar(context, e.message);
          }
        },
      ),
      body: colorsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load colors: $err')),
        data: (colors) {
          if (colors.isEmpty) {
            return const Center(child: Text('No colors yet. Add one to get started.'));
          }
          return ListView.separated(
            itemCount: colors.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final color = colors[index];
              return ListTile(
                leading: _swatch(color.hexCode),
                title: Text(color.name),
                trailing: const Icon(Icons.edit_outlined, size: 20),
                onTap: () async {
                  final result = await promptForColor(
                    context,
                    initialName: color.name,
                    initialHex: color.hexCode,
                  );
                  if (result == null) return;
                  try {
                    await ref
                        .read(catalogRepositoryProvider)
                        .updateColor(color.id, name: result.$1, hexCode: result.$2);
                    ref.invalidate(colorsProvider);
                    if (context.mounted) showSuccessSnackBar(context, 'Color updated.');
                  } on CatalogException catch (e) {
                    if (context.mounted) showErrorSnackBar(context, e.message);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _swatch(String? hexCode) {
    Color color = Colors.grey.shade300;
    if (hexCode != null && hexCode.length == 7) {
      final value = int.tryParse(hexCode.substring(1), radix: 16);
      if (value != null) color = Color(0xFF000000 | value);
    }
    return CircleAvatar(backgroundColor: color, radius: 14);
  }
}

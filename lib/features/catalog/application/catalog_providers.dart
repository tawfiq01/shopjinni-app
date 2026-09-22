import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/catalog_repository.dart';
import '../models/catalog_models.dart';

final brandsProvider = FutureProvider.autoDispose<List<Brand>>((ref) {
  return ref.watch(catalogRepositoryProvider).getBrands();
});

final productTypesProvider = FutureProvider.autoDispose<List<ProductType>>((ref) {
  return ref.watch(catalogRepositoryProvider).getProductTypes();
});

final colorsProvider = FutureProvider.autoDispose<List<ProductColor>>((ref) {
  return ref.watch(catalogRepositoryProvider).getColors();
});

class ModelSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final modelSearchProvider = NotifierProvider<ModelSearchNotifier, String>(ModelSearchNotifier.new);

final modelsProvider = FutureProvider.autoDispose<List<CatalogModel>>((ref) {
  final search = ref.watch(modelSearchProvider);
  return ref.watch(catalogRepositoryProvider).getModels(search: search);
});

final modelDetailProvider =
    FutureProvider.autoDispose.family<CatalogModel, int>((ref, modelId) {
  return ref.watch(catalogRepositoryProvider).getModel(modelId);
});

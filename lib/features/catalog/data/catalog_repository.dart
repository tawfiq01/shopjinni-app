import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_provider.dart';
import '../models/catalog_models.dart';

class CatalogException implements Exception {
  CatalogException(this.message);
  final String message;

  @override
  String toString() => message;
}

class CatalogRepository {
  CatalogRepository(this._dio);

  final Dio _dio;

  Future<T> _runAsync<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on DioException catch (e) {
      throw CatalogException(_extractMessage(e));
    }
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is Map<String, dynamic> && errors.isNotEmpty) {
        final firstField = errors.values.first;
        if (firstField is List && firstField.isNotEmpty) {
          return firstField.first.toString();
        }
      }
      if (data['message'] is String) return data['message'] as String;
    }
    return 'Something went wrong. Please check your connection and try again.';
  }

  Future<List<Brand>> getBrands() => _runAsync(() async {
    final res = await _dio.get('/catalog/brands');
    return (res.data['data'] as List).map((e) => Brand.fromJson(e)).toList();
  });

  Future<Brand> createBrand(String name) => _runAsync(() async {
    final res = await _dio.post('/catalog/brands', data: {'name': name});
    return Brand.fromJson(res.data['data']);
  });

  Future<Brand> updateBrand(int id, {String? name, bool? isActive}) =>
      _runAsync(() async {
        final res = await _dio.put(
          '/catalog/brands/$id',
          data: {'name': ?name, 'is_active': ?isActive},
        );
        return Brand.fromJson(res.data['data']);
      });

  Future<List<ProductType>> getProductTypes() => _runAsync(() async {
    final res = await _dio.get('/catalog/product-types');
    return (res.data['data'] as List)
        .map((e) => ProductType.fromJson(e))
        .toList();
  });

  Future<ProductType> createProductType(String name) => _runAsync(() async {
    final res = await _dio.post('/catalog/product-types', data: {'name': name});
    return ProductType.fromJson(res.data['data']);
  });

  Future<ProductType> updateProductType(int id, {String? name}) =>
      _runAsync(() async {
        final res = await _dio.put(
          '/catalog/product-types/$id',
          data: {'name': ?name},
        );
        return ProductType.fromJson(res.data['data']);
      });

  Future<List<ProductColor>> getColors() => _runAsync(() async {
    final res = await _dio.get('/catalog/colors');
    return (res.data['data'] as List)
        .map((e) => ProductColor.fromJson(e))
        .toList();
  });

  Future<ProductColor> createColor(String name, String? hexCode) =>
      _runAsync(() async {
        final res = await _dio.post(
          '/catalog/colors',
          data: {
            'name': name,
            if (hexCode != null && hexCode.isNotEmpty) 'hex_code': hexCode,
          },
        );
        return ProductColor.fromJson(res.data['data']);
      });

  Future<ProductColor> updateColor(int id, {String? name, String? hexCode}) =>
      _runAsync(() async {
        final res = await _dio.put(
          '/catalog/colors/$id',
          data: {'name': ?name, 'hex_code': ?hexCode},
        );
        return ProductColor.fromJson(res.data['data']);
      });

  Future<List<CatalogModel>> getModels({String? search, int? brandId}) =>
      _runAsync(() async {
        final res = await _dio.get(
          '/catalog/models',
          queryParameters: {
            if (search != null && search.isNotEmpty) 'search': search,
            'brand_id': ?brandId,
          },
        );
        return (res.data['data'] as List)
            .map((e) => CatalogModel.fromJson(e))
            .toList();
      });

  Future<CatalogModel> getModel(int id) => _runAsync(() async {
    final res = await _dio.get('/catalog/models/$id');
    return CatalogModel.fromJson(res.data['data']);
  });

  Future<List<CatalogProduct>> searchProducts(String search) =>
      _runAsync(() async {
        final res = await _dio.get(
          '/catalog/products',
          queryParameters: {
            'search': ?(search.isEmpty ? null : search),
            'per_page': 20,
          },
        );
        return (res.data['data'] as List)
            .map((e) => CatalogProduct.fromJson(e))
            .toList();
      });

  Future<CatalogModel> createModel({
    required int brandId,
    required int productTypeId,
    required String name,
    int? warrantyMonthsDefault,
    bool? imeiTrackingEnabled,
  }) => _runAsync(() async {
    final res = await _dio.post(
      '/catalog/models',
      data: {
        'brand_id': brandId,
        'product_type_id': productTypeId,
        'name': name,
        'warranty_months_default': ?warrantyMonthsDefault,
        'imei_tracking_enabled': ?imeiTrackingEnabled,
      },
    );
    return CatalogModel.fromJson(res.data['data']);
  });

  /// [warrantyMonthsDefault] and [imeiTrackingEnabled] are always sent as
  /// given — including `null`, which explicitly resets that field back to
  /// "inherit from product type" rather than leaving the prior value in
  /// place (the backend distinguishes an explicit null from an omitted key).
  Future<CatalogModel> updateModel(
    int id, {
    int? brandId,
    int? productTypeId,
    String? name,
    required int? warrantyMonthsDefault,
    required bool? imeiTrackingEnabled,
    bool? isActive,
  }) => _runAsync(() async {
    final res = await _dio.put(
      '/catalog/models/$id',
      data: {
        'brand_id': ?brandId,
        'product_type_id': ?productTypeId,
        'name': ?name,
        'warranty_months_default': warrantyMonthsDefault,
        'imei_tracking_enabled': imeiTrackingEnabled,
        'is_active': ?isActive,
      },
    );
    return CatalogModel.fromJson(res.data['data']);
  });

  Future<ProductVariant> createVariant({
    required int modelId,
    String? ram,
    String? storage,
    String? extraSpec,
  }) => _runAsync(() async {
    final res = await _dio.post(
      '/catalog/models/$modelId/variants',
      data: {
        if (ram != null && ram.isNotEmpty) 'ram': ram,
        if (storage != null && storage.isNotEmpty) 'storage': storage,
        if (extraSpec != null && extraSpec.isNotEmpty) 'extra_spec': extraSpec,
      },
    );
    return ProductVariant.fromJson(res.data['data']);
  });

  Future<ProductVariant> updateVariant(
    int id, {
    String? ram,
    String? storage,
    String? extraSpec,
    bool? isActive,
  }) => _runAsync(() async {
    final res = await _dio.put(
      '/catalog/variants/$id',
      data: {
        'ram': ?ram,
        'storage': ?storage,
        'extra_spec': ?extraSpec,
        'is_active': ?isActive,
      },
    );
    return ProductVariant.fromJson(res.data['data']);
  });

  Future<ProductSku> createSku({
    required int variantId,
    required int colorId,
    String? sku,
    String? barcode,
    bool? imeiTrackingEnabled,
    int? reorderLevel,
    double? sellingPriceCurrent,
  }) => _runAsync(() async {
    final res = await _dio.post(
      '/catalog/variants/$variantId/colors',
      data: {
        'color_id': colorId,
        if (sku != null && sku.isNotEmpty) 'sku': sku,
        if (barcode != null && barcode.isNotEmpty) 'barcode': barcode,
        'imei_tracking_enabled': ?imeiTrackingEnabled,
        'reorder_level': ?reorderLevel,
        'selling_price_current': ?sellingPriceCurrent,
      },
    );
    return ProductSku.fromJson(res.data['data']);
  });

  /// [imeiTrackingEnabled] is always sent as given — including `null`, which
  /// explicitly resets it back to "inherit from model" (see [updateModel]).
  /// [barcode] is sent as an explicit null when cleared to an empty string,
  /// so it's actually removed rather than tripping the uniqueness check with
  /// a stray "" value the next time another SKU's barcode is cleared too.
  Future<ProductSku> updateSku(
    int id, {
    String? sku,
    int? colorId,
    String? barcode,
    required bool? imeiTrackingEnabled,
    int? warrantyMonths,
    int? reorderLevel,
    double? sellingPriceCurrent,
    bool? isActive,
  }) => _runAsync(() async {
    final res = await _dio.put(
      '/catalog/products/$id',
      data: {
        'sku': ?sku,
        'color_id': ?colorId,
        'barcode': (barcode == null || barcode.isEmpty) ? null : barcode,
        'imei_tracking_enabled': imeiTrackingEnabled,
        'warranty_months': ?warrantyMonths,
        'reorder_level': ?reorderLevel,
        'selling_price_current': ?sellingPriceCurrent,
        'is_active': ?isActive,
      },
    );
    return ProductSku.fromJson(res.data['data']);
  });
}

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(dioProvider));
});

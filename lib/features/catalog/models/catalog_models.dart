class Brand {
  const Brand({required this.id, required this.name, required this.isActive});

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
        id: json['id'] as int,
        name: json['name'] as String,
        isActive: json['is_active'] as bool,
      );

  final int id;
  final String name;
  final bool isActive;
}

class ProductType {
  const ProductType({
    required this.id,
    required this.name,
    required this.imeiTrackingDefault,
    required this.isActive,
  });

  factory ProductType.fromJson(Map<String, dynamic> json) => ProductType(
        id: json['id'] as int,
        name: json['name'] as String,
        imeiTrackingDefault: json['imei_tracking_default'] as bool?,
        isActive: json['is_active'] as bool,
      );

  final int id;
  final String name;
  final bool? imeiTrackingDefault;
  final bool isActive;
}

class ProductColor {
  const ProductColor({required this.id, required this.name, this.hexCode});

  factory ProductColor.fromJson(Map<String, dynamic> json) => ProductColor(
        id: json['id'] as int,
        name: json['name'] as String,
        hexCode: json['hex_code'] as String?,
      );

  final int id;
  final String name;
  final String? hexCode;
}

class ProductSku {
  const ProductSku({
    required this.id,
    required this.sku,
    required this.barcode,
    required this.imeiTrackingEnabled,
    required this.imeiTrackingOverride,
    required this.reorderLevel,
    required this.sellingPriceCurrent,
    required this.isActive,
    required this.color,
    required this.displayName,
  });

  factory ProductSku.fromJson(Map<String, dynamic> json) => ProductSku(
        id: json['id'] as int,
        sku: json['sku'] as String,
        barcode: json['barcode'] as String?,
        imeiTrackingEnabled: json['imei_tracking_enabled'] as bool,
        imeiTrackingOverride: json['imei_tracking_override'] as bool?,
        reorderLevel: json['reorder_level'] as int,
        sellingPriceCurrent: json['selling_price_current'] == null
            ? null
            : double.tryParse('${json['selling_price_current']}'),
        isActive: json['is_active'] as bool,
        color: ProductColor.fromJson(json['color'] as Map<String, dynamic>),
        displayName: json['display_name'] as String,
      );

  final int id;
  final String sku;
  final String? barcode;
  /// Resolved value (always a definite yes/no) — use this to decide whether
  /// to show IMEI fields in POS/purchasing forms.
  final bool imeiTrackingEnabled;
  /// Raw override — null means "inherits from the model/product type".
  /// Use this (not [imeiTrackingEnabled]) to pre-fill an edit form, so
  /// saving without touching it doesn't accidentally freeze in a hardcoded
  /// value where it used to inherit.
  final bool? imeiTrackingOverride;
  final int reorderLevel;
  /// The MRP / current selling price shown to cashiers in POS. Null means
  /// no price has been set yet — POS will require manual entry per sale.
  final double? sellingPriceCurrent;
  final bool isActive;
  final ProductColor color;
  final String displayName;
}

class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.ram,
    required this.storage,
    required this.extraSpec,
    required this.label,
    required this.colors,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
        id: json['id'] as int,
        ram: json['ram'] as String?,
        storage: json['storage'] as String?,
        extraSpec: json['extra_spec'] as String?,
        label: json['label'] as String,
        colors: (json['colors'] as List<dynamic>? ?? [])
            .map((e) => ProductSku.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final int id;
  final String? ram;
  final String? storage;
  final String? extraSpec;
  final String label;
  final List<ProductSku> colors;
}

/// A flat, searchable SKU — the shape returned by GET /catalog/products,
/// used by the purchase form's product picker and (later) POS search.
class CatalogProduct {
  const CatalogProduct({
    required this.id,
    required this.sku,
    required this.barcode,
    required this.imeiTrackingEnabled,
    required this.displayName,
    required this.brandName,
    required this.modelName,
    required this.variantLabel,
    required this.colorName,
  });

  factory CatalogProduct.fromJson(Map<String, dynamic> json) => CatalogProduct(
        id: json['id'] as int,
        sku: json['sku'] as String,
        barcode: json['barcode'] as String?,
        imeiTrackingEnabled: json['imei_tracking_enabled'] as bool,
        displayName: json['display_name'] as String,
        brandName: json['brand']['name'] as String,
        modelName: json['model']['name'] as String,
        variantLabel: json['variant']['label'] as String,
        colorName: json['color']['name'] as String,
      );

  final int id;
  final String sku;
  final String? barcode;
  final bool imeiTrackingEnabled;
  final String displayName;
  final String brandName;
  final String modelName;
  final String variantLabel;
  final String colorName;
}

class CatalogModel {
  const CatalogModel({
    required this.id,
    required this.name,
    required this.warrantyMonthsDefault,
    required this.imeiTrackingEnabled,
    required this.isActive,
    required this.brand,
    required this.productType,
    required this.variants,
  });

  factory CatalogModel.fromJson(Map<String, dynamic> json) => CatalogModel(
        id: json['id'] as int,
        name: json['name'] as String,
        warrantyMonthsDefault: json['warranty_months_default'] as int?,
        imeiTrackingEnabled: json['imei_tracking_enabled'] as bool?,
        isActive: json['is_active'] as bool,
        brand: Brand.fromJson(json['brand'] as Map<String, dynamic>),
        productType: ProductType.fromJson(json['product_type'] as Map<String, dynamic>),
        variants: (json['variants'] as List<dynamic>? ?? [])
            .map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final int id;
  final String name;
  final int? warrantyMonthsDefault;
  /// Raw override — null means "inherits from the product type".
  final bool? imeiTrackingEnabled;
  final bool isActive;
  final Brand brand;
  final ProductType productType;
  final List<ProductVariant> variants;
}

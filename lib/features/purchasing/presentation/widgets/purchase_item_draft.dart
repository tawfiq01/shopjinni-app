import '../../../catalog/models/catalog_models.dart';
import '../../data/purchase_repository.dart';

class PurchaseItemDraft {
  PurchaseItemDraft({
    required this.product,
    required this.quantity,
    required this.unitCost,
    this.discount = 0,
    this.tax = 0,
    this.warrantyMonths,
    this.imeis = const [],
    this.demoQuantity = 0,
  });

  final CatalogProduct product;
  final int quantity;
  final double unitCost;
  final double discount;
  final double tax;
  final int? warrantyMonths;
  final List<ImeiEntry> imeis;
  final int demoQuantity;

  double get lineTotal => quantity * unitCost - discount + tax;

  PurchaseItemInput toInput() => PurchaseItemInput(
        productVariantColorId: product.id,
        quantity: quantity,
        unitCost: unitCost,
        discount: discount,
        tax: tax,
        warrantyMonths: warrantyMonths,
        imeis: imeis,
        demoQuantity: demoQuantity,
      );
}

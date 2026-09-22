import 'package:flutter/material.dart';

import '../../data/sales_repository.dart';
import '../../models/sale_models.dart';

class CartLine {
  CartLine({
    required this.productVariantColorId,
    required this.displayName,
    required this.isImei,
    this.imeiUnitId,
    this.imei1,
    this.isDemo = false,
    this.availableQuantity,
    int quantity = 1,
    double unitPrice = 0,
    double discount = 0,
  })  : quantity = ValueNotifier(quantity),
        unitPriceController = TextEditingController(text: unitPrice.toStringAsFixed(2)),
        discountController = TextEditingController(text: discount.toStringAsFixed(2));

  factory CartLine.fromCandidate(PosCandidate candidate) => CartLine(
        productVariantColorId: candidate.productVariantColorId,
        displayName: candidate.displayName,
        isImei: candidate.isImei,
        imeiUnitId: candidate.imeiUnitId,
        imei1: candidate.imei1,
        isDemo: candidate.isDemo,
        availableQuantity: candidate.availableQuantity,
        unitPrice: candidate.sellingPriceCurrent ?? 0,
      );

  final int productVariantColorId;
  final String displayName;
  final bool isImei;
  final int? imeiUnitId;
  final String? imei1;
  final bool isDemo;
  final int? availableQuantity;
  final ValueNotifier<int> quantity;
  final TextEditingController unitPriceController;
  final TextEditingController discountController;

  double get unitPrice => double.tryParse(unitPriceController.text.trim()) ?? 0;
  double get discount => double.tryParse(discountController.text.trim()) ?? 0;
  double get lineTotal => quantity.value * unitPrice - discount;

  SaleItemInput toInput() => SaleItemInput(
        productVariantColorId: productVariantColorId,
        imeiUnitId: imeiUnitId,
        quantity: quantity.value,
        unitPrice: unitPrice,
        discount: discount,
      );

  void dispose() {
    quantity.dispose();
    unitPriceController.dispose();
    discountController.dispose();
  }
}

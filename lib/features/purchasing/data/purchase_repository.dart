import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_provider.dart';
import '../models/purchase_models.dart';

class PurchaseException implements Exception {
  PurchaseException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ImeiEntry {
  ImeiEntry({required this.imei1, this.imei2, this.serialNumber, this.isDemo = false});
  final String imei1;
  final String? imei2;
  final String? serialNumber;
  final bool isDemo;

  Map<String, dynamic> toJson() => {
        'imei1': imei1,
        'imei2': ?imei2,
        'serial_number': ?serialNumber,
        'is_demo': isDemo,
      };
}

class PurchaseItemInput {
  PurchaseItemInput({
    required this.productVariantColorId,
    required this.quantity,
    required this.unitCost,
    this.discount,
    this.tax,
    this.warrantyMonths,
    this.imeis = const [],
  });

  final int productVariantColorId;
  final int quantity;
  final double unitCost;
  final double? discount;
  final double? tax;
  final int? warrantyMonths;
  final List<ImeiEntry> imeis;

  Map<String, dynamic> toJson() => {
        'product_variant_color_id': productVariantColorId,
        'quantity': quantity,
        'unit_cost': unitCost,
        'discount': ?discount,
        'tax': ?tax,
        'warranty_months': ?warrantyMonths,
        if (imeis.isNotEmpty) 'imeis': imeis.map((e) => e.toJson()).toList(),
      };
}

class PurchasePaymentInput {
  PurchasePaymentInput({required this.paymentMethodId, required this.amount, this.referenceNo});
  final int paymentMethodId;
  final double amount;
  final String? referenceNo;

  Map<String, dynamic> toJson() => {
        'payment_method_id': paymentMethodId,
        'amount': amount,
        'reference_no': ?referenceNo,
      };
}

class PurchaseRepository {
  PurchaseRepository(this._dio);

  final Dio _dio;

  Future<T> _run<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final errors = data['errors'];
        if (errors is Map<String, dynamic> && errors.isNotEmpty) {
          final firstField = errors.values.first;
          if (firstField is List && firstField.isNotEmpty) {
            throw PurchaseException(firstField.first.toString());
          }
        }
        if (data['message'] is String) {
          throw PurchaseException(data['message'] as String);
        }
      }
      throw PurchaseException('Something went wrong. Please check your connection and try again.');
    }
  }

  Future<List<PurchaseInvoice>> getPurchases() => _run(() async {
        final res = await _dio.get('/purchases');
        return (res.data['data'] as List).map((e) => PurchaseInvoice.fromJson(e)).toList();
      });

  Future<List<PaymentMethodOption>> getPaymentMethods() => _run(() async {
        final res = await _dio.get('/payment-methods');
        return (res.data['data'] as List).map((e) => PaymentMethodOption.fromJson(e)).toList();
      });

  Future<PurchaseInvoice> createPurchase({
    required int distributorId,
    required String purchaseDate,
    String? invoiceNumber,
    required List<PurchaseItemInput> items,
    List<PurchasePaymentInput> payments = const [],
  }) =>
      _run(() async {
        final res = await _dio.post('/purchases', data: {
          'distributor_id': distributorId,
          'purchase_date': purchaseDate,
          'invoice_number': ?invoiceNumber,
          'items': items.map((e) => e.toJson()).toList(),
          if (payments.isNotEmpty) 'payments': payments.map((e) => e.toJson()).toList(),
        });
        return PurchaseInvoice.fromJson(res.data['data']);
      });

  Future<PurchaseInvoice> getPurchase(int id) => _run(() async {
        final res = await _dio.get('/purchases/$id');
        return PurchaseInvoice.fromJson(res.data['data']);
      });

  Future<void> createPurchaseReturn({
    required int purchaseInvoiceId,
    required String returnDate,
    required int purchaseItemId,
    required int quantity,
    int? imeiUnitId,
    String? reason,
  }) =>
      _run(() async {
        await _dio.post('/purchase-returns', data: {
          'purchase_invoice_id': purchaseInvoiceId,
          'return_date': returnDate,
          'reason': ?reason,
          'items': [
            {
              'purchase_item_id': purchaseItemId,
              'quantity': quantity,
              'imei_unit_id': ?imeiUnitId,
            }
          ],
        });
      });
}

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return PurchaseRepository(ref.watch(dioProvider));
});

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_provider.dart';
import '../models/sale_models.dart';

class SalesException implements Exception {
  SalesException(this.message);
  final String message;

  @override
  String toString() => message;
}

class SaleItemInput {
  SaleItemInput({
    required this.productVariantColorId,
    required this.quantity,
    required this.unitPrice,
    this.imeiUnitId,
    this.discount,
  });

  final int productVariantColorId;
  final int? imeiUnitId;
  final int quantity;
  final double unitPrice;
  final double? discount;

  Map<String, dynamic> toJson() => {
        'product_variant_color_id': productVariantColorId,
        'imei_unit_id': ?imeiUnitId,
        'quantity': quantity,
        'unit_price': unitPrice,
        'discount': ?discount,
      };
}

class SalePaymentInput {
  SalePaymentInput({required this.paymentMethodId, required this.amount});
  final int paymentMethodId;
  final double amount;

  Map<String, dynamic> toJson() => {'payment_method_id': paymentMethodId, 'amount': amount};
}

class SalesRepository {
  SalesRepository(this._dio);

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
            throw SalesException(firstField.first.toString());
          }
        }
        if (data['message'] is String) {
          throw SalesException(data['message'] as String);
        }
      }
      throw SalesException('Something went wrong. Please check your connection and try again.');
    }
  }

  Future<List<PosCandidate>> search(String query, {int? branchId}) => _run(() async {
        final res = await _dio.get('/pos/search', queryParameters: {
          'q': query,
          'branch_id': ?branchId,
        });
        return (res.data['data'] as List).map((e) => PosCandidate.fromJson(e)).toList();
      });

  Future<List<SalesInvoiceSummary>> getSales() => _run(() async {
        final res = await _dio.get('/sales');
        return (res.data['data'] as List).map((e) => SalesInvoiceSummary.fromJson(e)).toList();
      });

  Future<SalesInvoiceSummary> createSale({
    int? customerId,
    required String saleDate,
    required List<SaleItemInput> items,
    List<SalePaymentInput> payments = const [],
  }) =>
      _run(() async {
        final res = await _dio.post('/sales', data: {
          'customer_id': ?customerId,
          'sale_date': saleDate,
          'items': items.map((e) => e.toJson()).toList(),
          if (payments.isNotEmpty) 'payments': payments.map((e) => e.toJson()).toList(),
        });
        return SalesInvoiceSummary.fromJson(res.data['data']);
      });

  Future<SalesInvoiceSummary> getSale(int id) => _run(() async {
        final res = await _dio.get('/sales/$id');
        return SalesInvoiceSummary.fromJson(res.data['data']);
      });

  Future<void> createSalesReturn({
    required int salesInvoiceId,
    required String returnDate,
    required int saleItemId,
    required int quantity,
    required String condition,
    required bool restocked,
    int? refundMethodId,
    String? reason,
  }) =>
      _run(() async {
        await _dio.post('/sales-returns', data: {
          'sales_invoice_id': salesInvoiceId,
          'return_date': returnDate,
          'refund_method_id': ?refundMethodId,
          'reason': ?reason,
          'items': [
            {
              'sale_item_id': saleItemId,
              'quantity': quantity,
              'condition': condition,
              'restocked': restocked,
            }
          ],
        });
      });

  Future<Map<String, dynamic>> createPhoneExchange({
    int? customerId,
    required String exchangeDate,
    required int oldProductVariantColorId,
    required double exchangeValue,
    String? oldImei1,
    String? oldImei2,
    String? oldSerialNumber,
    int? oldWarrantyMonths,
    required int newProductVariantColorId,
    int? newImeiUnitId,
    required double newUnitPrice,
    int? paymentMethodId,
    double? paymentAmount,
    int? refundMethodId,
  }) =>
      _run(() async {
        final res = await _dio.post('/phone-exchanges', data: {
          'customer_id': ?customerId,
          'exchange_date': exchangeDate,
          'old_phone': {
            'product_variant_color_id': oldProductVariantColorId,
            'exchange_value': exchangeValue,
            'imei1': ?oldImei1,
            'imei2': ?oldImei2,
            'serial_number': ?oldSerialNumber,
            'warranty_months': ?oldWarrantyMonths,
          },
          'new_phone': {
            'product_variant_color_id': newProductVariantColorId,
            'imei_unit_id': ?newImeiUnitId,
            'unit_price': newUnitPrice,
          },
          if (paymentMethodId != null && paymentAmount != null && paymentAmount > 0)
            'payments': [
              {'payment_method_id': paymentMethodId, 'amount': paymentAmount}
            ],
          'refund_method_id': ?refundMethodId,
        });
        return res.data['data'] as Map<String, dynamic>;
      });
}

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepository(ref.watch(dioProvider));
});

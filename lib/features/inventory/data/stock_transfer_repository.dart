import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_provider.dart';
import '../models/stock_transfer_models.dart';

class StockTransferException implements Exception {
  StockTransferException(this.message);
  final String message;

  @override
  String toString() => message;
}

class StockTransferItemInput {
  StockTransferItemInput({
    required this.productVariantColorId,
    required this.quantity,
    this.imeiUnitId,
  });

  final int productVariantColorId;
  final int quantity;
  final int? imeiUnitId;

  Map<String, dynamic> toJson() => {
        'product_variant_color_id': productVariantColorId,
        'quantity': quantity,
        'imei_unit_id': ?imeiUnitId,
      };
}

class StockTransferRepository {
  StockTransferRepository(this._dio);

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
            throw StockTransferException(firstField.first.toString());
          }
        }
        if (data['message'] is String) {
          throw StockTransferException(data['message'] as String);
        }
      }
      throw StockTransferException('Something went wrong. Please check your connection and try again.');
    }
  }

  Future<List<StockTransferSummary>> getTransfers() => _run(() async {
        final res = await _dio.get('/stock-transfers');
        return (res.data['data'] as List).map((e) => StockTransferSummary.fromJson(e)).toList();
      });

  Future<StockTransferSummary> createTransfer({
    required int fromBranchId,
    required int toBranchId,
    required String transferDate,
    required List<StockTransferItemInput> items,
    String? notes,
  }) =>
      _run(() async {
        final res = await _dio.post('/stock-transfers', data: {
          'from_branch_id': fromBranchId,
          'to_branch_id': toBranchId,
          'transfer_date': transferDate,
          'notes': ?notes,
          'items': items.map((e) => e.toJson()).toList(),
        });
        return StockTransferSummary.fromJson(res.data['data']);
      });
}

final stockTransferRepositoryProvider = Provider<StockTransferRepository>((ref) {
  return StockTransferRepository(ref.watch(dioProvider));
});

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_provider.dart';
import '../models/report_models.dart';

class ReportsException implements Exception {
  ReportsException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ReportsRepository {
  ReportsRepository(this._dio);

  final Dio _dio;

  Future<T> _run<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['message'] is String) {
        throw ReportsException(data['message'] as String);
      }
      throw ReportsException('Something went wrong. Please check your connection and try again.');
    }
  }

  Future<StockReport> getStockReport({bool lowStockOnly = false, String? search}) => _run(() async {
        final res = await _dio.get('/reports/stock', queryParameters: {
          if (lowStockOnly) 'low_stock_only': true,
          if (search != null && search.isNotEmpty) 'search': search,
        });
        return StockReport.fromJson(res.data);
      });

  Future<ImeiHistory?> getImeiHistory(String imei) => _run(() async {
        try {
          final res = await _dio.get('/reports/imei-history', queryParameters: {'imei': imei});
          return ImeiHistory.fromJson(res.data);
        } on DioException catch (e) {
          if (e.response?.statusCode == 404) return null;
          rethrow;
        }
      });

  Future<SalesSummary> getSalesSummary() => _run(() async {
        final res = await _dio.get('/reports/sales/summary');
        return SalesSummary.fromJson(res.data);
      });

  Future<PurchaseSummary> getPurchaseSummary() => _run(() async {
        final res = await _dio.get('/reports/purchases/summary');
        return PurchaseSummary.fromJson(res.data);
      });

  Future<List<PurchasePriceHistoryRow>> getPurchasePriceHistory(int skuId) => _run(() async {
        final res = await _dio.get('/reports/purchases/price-history', queryParameters: {'sku_id': skuId});
        return (res.data['data'] as List)
            .map((e) => PurchasePriceHistoryRow.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  Future<DuesReport> getDues() => _run(() async {
        final res = await _dio.get('/reports/dues');
        return DuesReport.fromJson(res.data);
      });

  Future<StockMovementHistory> getStockMovements(int skuId) => _run(() async {
        final res = await _dio.get('/reports/stock-movements', queryParameters: {'sku_id': skuId});
        return StockMovementHistory.fromJson(res.data);
      });

  Future<List<CashPositionRow>> getCashPosition() => _run(() async {
        final res = await _dio.get('/reports/cash-position');
        return (res.data['data'] as List).map((e) => CashPositionRow.fromJson(e)).toList();
      });
}

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(ref.watch(dioProvider));
});

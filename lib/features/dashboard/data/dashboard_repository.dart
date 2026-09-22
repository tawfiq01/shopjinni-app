import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_provider.dart';
import '../models/dashboard_summary.dart';

class DashboardException implements Exception {
  DashboardException(this.message);
  final String message;

  @override
  String toString() => message;
}

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  Future<DashboardSummary> getSummary() async {
    try {
      final res = await _dio.get('/dashboard/summary');
      return DashboardSummary.fromJson(res.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['message'] is String) {
        throw DashboardException(data['message'] as String);
      }
      throw DashboardException('Something went wrong. Please check your connection and try again.');
    }
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioProvider));
});

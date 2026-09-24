import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_provider.dart';
import '../models/admin_company.dart';
import '../models/admin_payment.dart';
import '../models/admin_plan.dart';
import '../models/admin_report_summary.dart';

class AdminException implements Exception {
  AdminException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AdminRepository {
  AdminRepository(this._dio);

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
            throw AdminException(firstField.first.toString());
          }
        }
        if (data['message'] is String) {
          throw AdminException(data['message'] as String);
        }
      }
      throw AdminException('Something went wrong. Please check your connection and try again.');
    }
  }

  Future<List<AdminCompany>> getCompanies() => _run(() async {
        final res = await _dio.get('/admin/companies');
        return (res.data['data'] as List<dynamic>)
            .map((e) => AdminCompany.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  Future<void> activateCompany(int companyId) => _run(() async {
        await _dio.post('/admin/companies/$companyId/activate');
      });

  Future<void> deactivateCompany(int companyId) => _run(() async {
        await _dio.post('/admin/companies/$companyId/deactivate');
      });

  Future<void> setSubscriptionStatus(int companyId, String status) => _run(() async {
        await _dio.put('/admin/subscriptions/$companyId/status', data: {'status': status});
      });

  Future<List<AdminPlan>> getPlans() => _run(() async {
        final res = await _dio.get('/admin/plans');
        return (res.data['data'] as List<dynamic>).map((e) => AdminPlan.fromJson(e as Map<String, dynamic>)).toList();
      });

  Future<void> createPlan(Map<String, dynamic> data) => _run(() async {
        await _dio.post('/admin/plans', data: data);
      });

  Future<void> updatePlan(int planId, Map<String, dynamic> data) => _run(() async {
        await _dio.put('/admin/plans/$planId', data: data);
      });

  Future<List<AdminPayment>> getPayments() => _run(() async {
        final res = await _dio.get('/admin/payments');
        return (res.data['data'] as List<dynamic>)
            .map((e) => AdminPayment.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  Future<void> recordPayment({
    required int companyId,
    required String method,
    required String billingCycle,
    String? reference,
    String? notes,
  }) =>
      _run(() async {
        await _dio.post('/admin/payments', data: {
          'company_id': companyId,
          'method': method,
          'billing_cycle': billingCycle,
          'reference': ?reference,
          'notes': ?notes,
        });
      });

  Future<AdminReportSummary> getReportSummary() => _run(() async {
        final res = await _dio.get('/admin/reports/summary');
        return AdminReportSummary.fromJson(res.data as Map<String, dynamic>);
      });
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(dioProvider));
});

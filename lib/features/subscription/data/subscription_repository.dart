import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_provider.dart';
import '../models/company_subscription.dart';

class SubscriptionException implements Exception {
  SubscriptionException(this.message);
  final String message;

  @override
  String toString() => message;
}

class SubscriptionRepository {
  SubscriptionRepository(this._dio);

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
            throw SubscriptionException(firstField.first.toString());
          }
        }
        if (data['message'] is String) {
          throw SubscriptionException(data['message'] as String);
        }
      }
      throw SubscriptionException('Something went wrong. Please check your connection and try again.');
    }
  }

  Future<CompanySubscription> getCurrent() => _run(() async {
        final res = await _dio.get('/company/subscription');
        return CompanySubscription.fromJson(res.data as Map<String, dynamic>);
      });

  Future<List<SubscriptionPlanSummary>> getPlans() => _run(() async {
        final res = await _dio.get('/subscription/plans');
        return (res.data['data'] as List<dynamic>)
            .map((e) => SubscriptionPlanSummary.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  Future<CompanySubscription> changePlan(int planId) => _run(() async {
        final res = await _dio.put('/company/subscription/plan', data: {'plan_id': planId});
        return CompanySubscription.fromJson(res.data as Map<String, dynamic>);
      });
}

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(ref.watch(dioProvider));
});

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_provider.dart';
import '../../accounting/models/accounting_models.dart';
import '../models/customer.dart';

class CustomerException implements Exception {
  CustomerException(this.message);
  final String message;

  @override
  String toString() => message;
}

class CustomerRepository {
  CustomerRepository(this._dio);

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
            throw CustomerException(firstField.first.toString());
          }
        }
        if (data['message'] is String) {
          throw CustomerException(data['message'] as String);
        }
      }
      throw CustomerException('Something went wrong. Please check your connection and try again.');
    }
  }

  Future<List<Customer>> getCustomers({String? search}) => _run(() async {
        final res = await _dio.get('/customers', queryParameters: {
          'search': ?search,
        });
        return (res.data['data'] as List).map((e) => Customer.fromJson(e)).toList();
      });

  Future<Customer> createCustomer({
    required String name,
    required String mobile,
    String? address,
    String? email,
    double? openingBalance,
    double? creditLimit,
    String? notes,
  }) =>
      _run(() async {
        final res = await _dio.post('/customers', data: {
          'name': name,
          'mobile': mobile,
          'address': ?address,
          'email': ?email,
          'opening_balance': ?openingBalance,
          'credit_limit': ?creditLimit,
          'notes': ?notes,
        });
        return Customer.fromJson(res.data['data']);
      });

  Future<Customer> updateCustomer(
    int id, {
    String? name,
    String? mobile,
    String? address,
    String? email,
    double? creditLimit,
    String? notes,
    bool? isActive,
  }) =>
      _run(() async {
        final res = await _dio.put('/customers/$id', data: {
          'name': ?name,
          'mobile': ?mobile,
          'address': ?address,
          'email': ?email,
          'credit_limit': ?creditLimit,
          'notes': ?notes,
          'is_active': ?isActive,
        });
        return Customer.fromJson(res.data['data']);
      });

  Future<void> deleteCustomer(int id) => _run(() => _dio.delete('/customers/$id'));

  Future<List<LedgerLine>> getLedger(int id) => _run(() async {
        final res = await _dio.get('/customers/$id/ledger');
        return (res.data['lines'] as List).map((e) => LedgerLine.fromJson(e)).toList();
      });
}

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(ref.watch(dioProvider));
});

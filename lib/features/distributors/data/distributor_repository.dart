import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_provider.dart';
import '../../accounting/models/accounting_models.dart';
import '../models/distributor.dart';

class DistributorException implements Exception {
  DistributorException(this.message);
  final String message;

  @override
  String toString() => message;
}

class DistributorRepository {
  DistributorRepository(this._dio);

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
            throw DistributorException(firstField.first.toString());
          }
        }
        if (data['message'] is String) {
          throw DistributorException(data['message'] as String);
        }
      }
      throw DistributorException('Something went wrong. Please check your connection and try again.');
    }
  }

  Future<List<Distributor>> getDistributors({String? search}) => _run(() async {
        final res = await _dio.get('/distributors', queryParameters: {
          'search': ?search,
        });
        return (res.data['data'] as List).map((e) => Distributor.fromJson(e)).toList();
      });

  Future<Distributor> createDistributor({
    required String name,
    required String mobile,
    String? companyName,
    String? contactPerson,
    String? altMobile,
    String? address,
    String? email,
    double? openingBalance,
    double? creditLimit,
    String? paymentTerms,
    String? notes,
  }) =>
      _run(() async {
        final res = await _dio.post('/distributors', data: {
          'name': name,
          'mobile': mobile,
          'company_name': ?companyName,
          'contact_person': ?contactPerson,
          'alt_mobile': ?altMobile,
          'address': ?address,
          'email': ?email,
          'opening_balance': ?openingBalance,
          'credit_limit': ?creditLimit,
          'payment_terms': ?paymentTerms,
          'notes': ?notes,
        });
        return Distributor.fromJson(res.data['data']);
      });

  Future<Distributor> updateDistributor(
    int id, {
    String? name,
    String? mobile,
    String? companyName,
    String? contactPerson,
    String? altMobile,
    String? address,
    String? email,
    double? creditLimit,
    String? paymentTerms,
    String? notes,
    bool? isActive,
  }) =>
      _run(() async {
        final res = await _dio.put('/distributors/$id', data: {
          'name': ?name,
          'mobile': ?mobile,
          'company_name': ?companyName,
          'contact_person': ?contactPerson,
          'alt_mobile': ?altMobile,
          'address': ?address,
          'email': ?email,
          'credit_limit': ?creditLimit,
          'payment_terms': ?paymentTerms,
          'notes': ?notes,
          'is_active': ?isActive,
        });
        return Distributor.fromJson(res.data['data']);
      });

  Future<void> deleteDistributor(int id) => _run(() => _dio.delete('/distributors/$id'));

  Future<List<LedgerLine>> getLedger(int id) => _run(() async {
        final res = await _dio.get('/distributors/$id/ledger');
        return (res.data['lines'] as List).map((e) => LedgerLine.fromJson(e)).toList();
      });
}

final distributorRepositoryProvider = Provider<DistributorRepository>((ref) {
  return DistributorRepository(ref.watch(dioProvider));
});

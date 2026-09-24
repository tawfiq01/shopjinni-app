import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_provider.dart';
import '../models/company_details.dart';

class CompanyException implements Exception {
  CompanyException(this.message);
  final String message;

  @override
  String toString() => message;
}

class CompanyRepository {
  CompanyRepository(this._dio);

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
            throw CompanyException(firstField.first.toString());
          }
        }
        if (data['message'] is String) {
          throw CompanyException(data['message'] as String);
        }
      }
      throw CompanyException('Something went wrong. Please check your connection and try again.');
    }
  }

  Future<CompanyDetails> getCompany() => _run(() async {
        final res = await _dio.get('/company');
        return CompanyDetails.fromJson(res.data as Map<String, dynamic>);
      });

  Future<CompanyDetails> updateCompany({
    required String name,
    String? address,
    String? phone,
  }) =>
      _run(() async {
        final res = await _dio.put('/company', data: {
          'name': name,
          'address': ?address,
          'phone': ?phone,
        });
        return CompanyDetails.fromJson(res.data as Map<String, dynamic>);
      });

  Future<CompanyDetails> uploadLogo({required List<int> bytes, required String filename}) => _run(() async {
        final form = FormData.fromMap({
          'logo': MultipartFile.fromBytes(bytes, filename: filename),
        });
        final res = await _dio.post('/company/logo', data: form);
        return CompanyDetails.fromJson(res.data as Map<String, dynamic>);
      });

  Future<CompanyDetails> deleteLogo() => _run(() async {
        final res = await _dio.delete('/company/logo');
        return CompanyDetails.fromJson(res.data as Map<String, dynamic>);
      });
}

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepository(ref.watch(dioProvider));
});

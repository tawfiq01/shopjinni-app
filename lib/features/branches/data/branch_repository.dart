import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_provider.dart';
import '../models/branch.dart';

class BranchException implements Exception {
  BranchException(this.message);
  final String message;

  @override
  String toString() => message;
}

class BranchRepository {
  BranchRepository(this._dio);

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
            throw BranchException(firstField.first.toString());
          }
        }
        if (data['message'] is String) {
          throw BranchException(data['message'] as String);
        }
      }
      throw BranchException('Something went wrong. Please check your connection and try again.');
    }
  }

  Future<List<Branch>> getBranches() => _run(() async {
        final res = await _dio.get('/branches');
        return (res.data['data'] as List).map((e) => Branch.fromJson(e)).toList();
      });

  Future<Branch> createBranch({required String name, String? address, String? phone}) =>
      _run(() async {
        final res = await _dio.post('/branches', data: {
          'name': name,
          'address': ?address,
          'phone': ?phone,
        });
        return Branch.fromJson(res.data['data']);
      });

  Future<Branch> updateBranch(
    int id, {
    String? name,
    String? address,
    String? phone,
    bool? isActive,
  }) =>
      _run(() async {
        final res = await _dio.put('/branches/$id', data: {
          'name': ?name,
          'address': ?address,
          'phone': ?phone,
          'is_active': ?isActive,
        });
        return Branch.fromJson(res.data['data']);
      });
}

final branchRepositoryProvider = Provider<BranchRepository>((ref) {
  return BranchRepository(ref.watch(dioProvider));
});

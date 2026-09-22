import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_provider.dart';
import '../models/staff_user.dart';

class UserManagementException implements Exception {
  UserManagementException(this.message);
  final String message;

  @override
  String toString() => message;
}

class UserRepository {
  UserRepository(this._dio);

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
            throw UserManagementException(firstField.first.toString());
          }
        }
        if (data['message'] is String) {
          throw UserManagementException(data['message'] as String);
        }
      }
      throw UserManagementException('Something went wrong. Please check your connection and try again.');
    }
  }

  Future<List<StaffUser>> getUsers() => _run(() async {
        final res = await _dio.get('/users');
        return (res.data['data'] as List).map((e) => StaffUser.fromJson(e)).toList();
      });

  Future<List<String>> getRoles() => _run(() async {
        final res = await _dio.get('/roles');
        return (res.data['data'] as List).cast<String>();
      });

  Future<StaffUser> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    int? branchId,
  }) =>
      _run(() async {
        final res = await _dio.post('/users', data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          'phone': ?phone,
          'branch_id': ?branchId,
        });
        return StaffUser.fromJson(res.data['data']);
      });

  Future<StaffUser> updateUser(
    int id, {
    String? name,
    String? email,
    String? phone,
    int? branchId,
    bool? isActive,
    String? role,
  }) =>
      _run(() async {
        final res = await _dio.put('/users/$id', data: {
          'name': ?name,
          'email': ?email,
          'phone': ?phone,
          'branch_id': ?branchId,
          'is_active': ?isActive,
          'role': ?role,
        });
        return StaffUser.fromJson(res.data['data']);
      });

  Future<void> resetPassword(int id, String password) => _run(() async {
        await _dio.post('/users/$id/reset-password', data: {'password': password});
      });
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(dioProvider));
});

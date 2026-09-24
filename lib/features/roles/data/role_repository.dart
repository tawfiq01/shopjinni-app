import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_provider.dart';
import '../models/permission_catalog_entry.dart';
import '../models/role.dart';

class RoleException implements Exception {
  RoleException(this.message);
  final String message;

  @override
  String toString() => message;
}

class RoleRepository {
  RoleRepository(this._dio);

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
            throw RoleException(firstField.first.toString());
          }
        }
        if (data['message'] is String) {
          throw RoleException(data['message'] as String);
        }
      }
      throw RoleException('Something went wrong. Please check your connection and try again.');
    }
  }

  Future<List<Role>> getRoles() => _run(() async {
        final res = await _dio.get('/roles');
        return (res.data['data'] as List<dynamic>).map((e) => Role.fromJson(e as Map<String, dynamic>)).toList();
      });

  Future<List<PermissionCatalogEntry>> getPermissionCatalog() => _run(() async {
        final res = await _dio.get('/permissions');
        return (res.data['data'] as List<dynamic>)
            .map((e) => PermissionCatalogEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  Future<Role> createRole({required String name, required List<String> permissions}) => _run(() async {
        final res = await _dio.post('/roles', data: {'name': name, 'permissions': permissions});
        return Role.fromJson(res.data as Map<String, dynamic>);
      });

  Future<Role> updateRole(int id, {String? name, List<String>? permissions}) => _run(() async {
        final res = await _dio.put('/roles/$id', data: {
          'name': ?name,
          'permissions': ?permissions,
        });
        return Role.fromJson(res.data as Map<String, dynamic>);
      });

  Future<void> deleteRole(int id) => _run(() async {
        await _dio.delete('/roles/$id');
      });
}

final roleRepositoryProvider = Provider<RoleRepository>((ref) {
  return RoleRepository(ref.watch(dioProvider));
});

import 'package:dio/dio.dart';

import '../api/api_client.dart';
import 'app_user.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthResult {
  AuthResult({required this.token, required this.user});
  final String token;
  final AppUser user;
}

class AuthRepository {
  Future<AuthResult> login({
    required String email,
    required String password,
    String deviceName = 'mobishop-app',
  }) async {
    final client = ApiClient();
    try {
      final response = await client.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
        'device_name': deviceName,
      });
      final data = response.data as Map<String, dynamic>;
      return AuthResult(
        token: data['token'] as String,
        user: AppUser.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw AuthException(_extractMessage(e));
    }
  }

  Future<AppUser> me(String token) async {
    final client = ApiClient(token: token);
    try {
      final response = await client.dio.get('/auth/me');
      final data = response.data as Map<String, dynamic>;
      return AppUser.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthException(_extractMessage(e));
    }
  }

  Future<void> logout(String token) async {
    final client = ApiClient(token: token);
    try {
      await client.dio.post('/auth/logout');
    } on DioException {
      // Token may already be invalid server-side; ignore and clear locally regardless.
    }
  }

  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final client = ApiClient(token: token);
    try {
      await client.dio.post('/auth/change-password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPassword,
      });
    } on DioException catch (e) {
      throw AuthException(_extractMessage(e));
    }
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is Map<String, dynamic> && errors.isNotEmpty) {
        final firstField = errors.values.first;
        if (firstField is List && firstField.isNotEmpty) {
          return firstField.first.toString();
        }
      }
      if (data['message'] is String) {
        return data['message'] as String;
      }
    }
    return 'Something went wrong. Please check your connection and try again.';
  }
}

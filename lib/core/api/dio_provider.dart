import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_state.dart';
import 'api_client.dart';

/// Rebuilds whenever the auth token changes (login/logout), so every
/// downstream repository always talks to the API with the current token.
final dioProvider = Provider<Dio>((ref) {
  final token = ref.watch(authControllerProvider.select((s) => s.token));
  return ApiClient(token: token).dio;
});

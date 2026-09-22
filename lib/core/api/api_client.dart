import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

String _resolveBaseUrl() {
  if (kIsWeb) {
    return 'http://127.0.0.1:8000/api';
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    // 10.0.2.2 routes to the host machine's localhost from the Android emulator.
    return 'http://10.0.2.2:8000/api';
  }
  return 'http://127.0.0.1:8000/api';
}

class ApiClient {
  ApiClient({String? token})
      : dio = Dio(
          BaseOptions(
            baseUrl: _resolveBaseUrl(),
            headers: {
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          ),
        );

  final Dio dio;
}

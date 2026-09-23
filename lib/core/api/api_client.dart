import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

String _resolveBaseUrl() {
  if (kIsWeb) {
    // Whatever host the page itself was loaded from (localhost, or the
    // machine's LAN IP when another device on the network opens it) —
    // so the API call lands back on the same machine that served the app.
    final host = Uri.base.host.isNotEmpty ? Uri.base.host : '127.0.0.1';
    return 'http://$host:8000/api';
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

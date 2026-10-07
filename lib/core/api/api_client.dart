import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// Override at build time for a production build, e.g.:
//   flutter build web --release --dart-define=API_BASE_URL=https://app.shopjinne.com/api
// Left blank, every platform falls back to its own local-dev default below.
const _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

String _resolveBaseUrl() {
  if (_apiBaseUrlOverride.isNotEmpty) {
    return _apiBaseUrlOverride;
  }
  if (kIsWeb) {
    // Whatever host the page itself was loaded from (localhost, or the
    // machine's LAN IP when another device on the network opens it) —
    // so the API call lands back on the same machine that served the app.
    final host = Uri.base.host.isNotEmpty ? Uri.base.host : '127.0.0.1';
    return 'http://$host:8000/api';
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    // 10.0.2.2 routes to the host machine's localhost from the Android emulator.
    return 'http://192.168.80.85:8000/api';
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

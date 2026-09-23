import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// On web, [FlutterSecureStorage] relies on the browser's Web Crypto API,
/// which browsers only expose in secure contexts (HTTPS, or
/// http://localhost) — opening the app over plain HTTP from a LAN IP is not
/// a secure context, so every call throws. Left unhandled, that exception
/// is uncaught during the app's initial session restore, leaving auth state
/// stuck at `unknown` forever (a permanent blank splash screen). Falling
/// back to "no stored token" here just means the session won't persist
/// across a refresh on that kind of origin — the best any app can do
/// without HTTPS — instead of the app never loading at all.
class TokenStorage {
  TokenStorage() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _tokenKey = 'auth_token';

  Future<String?> read() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      debugPrint('TokenStorage.read failed, treating as no stored token: $e');
      return null;
    }
  }

  Future<void> save(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (e) {
      debugPrint('TokenStorage.save failed, session will not persist: $e');
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (e) {
      debugPrint('TokenStorage.clear failed: $e');
    }
  }
}

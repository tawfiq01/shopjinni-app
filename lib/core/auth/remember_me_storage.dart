import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the email/password entered on the login screen when "Remember
/// me" is checked, so the fields come back pre-filled next time — separate
/// from TokenStorage, which persists the actual session.
class RememberMeStorage {
  RememberMeStorage() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _emailKey = 'remembered_email';
  static const _passwordKey = 'remembered_password';

  Future<(String, String)?> read() async {
    try {
      final email = await _storage.read(key: _emailKey);
      final password = await _storage.read(key: _passwordKey);
      if (email == null || password == null) return null;
      return (email, password);
    } catch (e) {
      debugPrint('RememberMeStorage.read failed, treating as no stored credentials: $e');
      return null;
    }
  }

  Future<void> save(String email, String password) async {
    try {
      await _storage.write(key: _emailKey, value: email);
      await _storage.write(key: _passwordKey, value: password);
    } catch (e) {
      debugPrint('RememberMeStorage.save failed, credentials will not persist: $e');
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _emailKey);
      await _storage.delete(key: _passwordKey);
    } catch (e) {
      debugPrint('RememberMeStorage.clear failed: $e');
    }
  }
}

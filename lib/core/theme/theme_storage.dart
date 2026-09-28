import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeStorage {
  ThemeStorage() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _themeModeKey = 'theme_mode';

  Future<String?> read() async {
    try {
      return await _storage.read(key: _themeModeKey);
    } catch (e) {
      debugPrint('ThemeStorage.read failed, defaulting to system theme: $e');
      return null;
    }
  }

  Future<void> save(String value) async {
    try {
      await _storage.write(key: _themeModeKey, value: value);
    } catch (e) {
      debugPrint('ThemeStorage.save failed, theme choice will not persist: $e');
    }
  }
}

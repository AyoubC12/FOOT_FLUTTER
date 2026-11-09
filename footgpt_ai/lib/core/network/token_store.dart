import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  final Map<String, String> _memory = {};

  static const _accessKey = 'footgpt_access';
  static const _refreshKey = 'footgpt_refresh';

  Future<String?> readAccess() => _read(_accessKey);

  Future<String?> readRefresh() => _read(_refreshKey);

  Future<void> save({required String access, required String refresh}) async {
    await _write(_accessKey, access);
    await _write(_refreshKey, refresh);
  }

  Future<void> clear() async {
    _memory.clear();
    try {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
    } catch (_) {}
  }

  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key) ?? _memory[key];
    } catch (_) {
      return _memory[key];
    }
  }

  Future<void> _write(String key, String value) async {
    _memory[key] = value;
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {}
  }
}

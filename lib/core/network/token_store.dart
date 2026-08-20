import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the patient's bearer token between launches.
///
/// Uses the platform keystore rather than shared preferences: the token grants
/// access to a person's medical appointments, so it belongs in encrypted
/// storage, not a plain-text preferences file another app could read on a
/// rooted device.
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
    // This version of flutter_secure_storage encrypts on Android by default,
    // so no extra options are needed.
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'cihos_auth_token';

  final FlutterSecureStorage _storage;

  /// Cached in memory so repeated calls do not hit the keystore each request.
  String? _cached;
  bool _hasRead = false;

  Future<String?> read() async {
    if (_hasRead) return _cached;
    _cached = await _storage.read(key: _key);
    _hasRead = true;
    return _cached;
  }

  Future<void> write(String token) async {
    _cached = token;
    _hasRead = true;
    await _storage.write(key: _key, value: token);
  }

  Future<void> clear() async {
    _cached = null;
    _hasRead = true;
    await _storage.delete(key: _key);
  }
}

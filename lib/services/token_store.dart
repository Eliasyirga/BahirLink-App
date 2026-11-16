import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The only place the app reads, writes or deletes auth tokens.
///
/// Tokens live in the platform keystore (Android Keystore-backed cipher,
/// iOS/macOS Keychain) via flutter_secure_storage — never in plain
/// SharedPreferences. Non-secret prefs (userId, language, ...) stay in
/// SharedPreferences.
///
/// Older installs kept tokens in SharedPreferences under `accessToken`,
/// `token` and `refreshToken`. The first access through this class copies
/// them into secure storage (unless secure storage already has a value) and
/// then deletes them from SharedPreferences.
class TokenStore {
  TokenStore._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _accessKey = 'accessToken';
  static const String _refreshKey = 'refreshToken';

  /// Keys older builds used in plain SharedPreferences.
  static const String _legacyAccessKey = 'accessToken';
  static const String _legacyTokenKey = 'token';
  static const String _legacyRefreshKey = 'refreshToken';

  static Future<void>? _migration;

  static Future<void> _ensureMigrated() => _migration ??= _migrateLegacy();

  static Future<void> _migrateLegacy() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacyAccess =
          prefs.getString(_legacyAccessKey) ?? prefs.getString(_legacyTokenKey);
      final legacyRefresh = prefs.getString(_legacyRefreshKey);
      if (legacyAccess == null && legacyRefresh == null) return;

      if (legacyAccess != null &&
          legacyAccess.isNotEmpty &&
          (await _storage.read(key: _accessKey)) == null) {
        await _storage.write(key: _accessKey, value: legacyAccess);
      }
      if (legacyRefresh != null &&
          legacyRefresh.isNotEmpty &&
          (await _storage.read(key: _refreshKey)) == null) {
        await _storage.write(key: _refreshKey, value: legacyRefresh);
      }

      // Only drop the plaintext copies once secure storage has them.
      await prefs.remove(_legacyAccessKey);
      await prefs.remove(_legacyTokenKey);
      await prefs.remove(_legacyRefreshKey);
    } catch (e) {
      debugPrint('TokenStore: legacy token migration failed: $e');
      _migration = null; // retry on next access
    }
  }

  static Future<String?> _read(String key) async {
    await _ensureMigrated();
    try {
      final value = await _storage.read(key: key);
      return (value == null || value.isEmpty) ? null : value;
    } catch (e) {
      debugPrint('TokenStore: read "$key" failed: $e');
      return null;
    }
  }

  /// The current access token, or null when signed out.
  static Future<String?> readAccessToken() => _read(_accessKey);

  /// The current refresh token, or null when none was issued.
  static Future<String?> readRefreshToken() => _read(_refreshKey);

  /// Persists the tokens returned by a successful login. A null
  /// [refreshToken] leaves any stored refresh token untouched.
  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _ensureMigrated();
    await _storage.write(key: _accessKey, value: accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: _refreshKey, value: refreshToken);
    }
  }

  /// Deletes every stored token, including any leftover plaintext copies
  /// from older builds.
  static Future<void> clear() async {
    try {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
    } catch (e) {
      debugPrint('TokenStore: delete failed: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyAccessKey);
    await prefs.remove(_legacyTokenKey);
    await prefs.remove(_legacyRefreshKey);
  }
}

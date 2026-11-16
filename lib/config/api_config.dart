/// Single source of truth for the backend location.
///
/// Override at build/run time, e.g. for local development:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000   (Android emulator)
///   flutter run --dart-define=API_BASE_URL=http://localhost:5000  (web / iOS sim / desktop)
class ApiConfig {
  ApiConfig._();

  /// Backend origin, without a trailing slash and without `/api`.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://bahirlink-backend-1.onrender.com',
  );

  /// Convenience: `<baseUrl>/api`.
  static const String apiUrl = '$baseUrl/api';

  /// Resolves a media path returned by the backend. Absolute URLs (e.g.
  /// Cloudinary) are returned unchanged; relative paths are prefixed with
  /// [baseUrl].
  static String resolveMediaUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return url.startsWith('/') ? '$baseUrl$url' : '$baseUrl/$url';
  }
}

/// Thrown when the backend rejects the access token (HTTP 401) — the user
/// must log in again.
class SessionExpiredException implements Exception {
  const SessionExpiredException();

  @override
  String toString() => 'Your session has expired. Please log in again.';
}

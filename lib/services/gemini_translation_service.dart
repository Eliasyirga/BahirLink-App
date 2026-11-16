import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_config_service.dart';

class GeminiTranslationResult {
  final String en;
  final String am;
  final String originalLanguage;

  const GeminiTranslationResult({
    required this.en,
    required this.am,
    required this.originalLanguage,
  });
}

/// Thrown for any failed translation. [statusCode] is null for network /
/// timeout / parse failures. Backend codes: 400 bad input, 429 rate-limited,
/// 502 upstream (Gemini) error, 503 translation not configured.
class TranslationException implements Exception {
  final int? statusCode;
  final String message;

  const TranslationException(this.message, {this.statusCode});

  @override
  String toString() => 'TranslationException($statusCode): $message';
}

/// Client for `POST /api/translation/gemini`
/// (`{text, sourceLanguage?, targetLanguage?, model?}` →
/// `{en, am, originalLanguage}`).
class GeminiTranslationService {
  static const Duration _timeout = Duration(seconds: 15);
  static const int _maxCacheEntries = 200;

  /// In-memory cache keyed by the (trimmed) source text. Stores the Future so
  /// concurrent requests for the same text share one network call. Failed
  /// lookups are evicted so they can be retried later.
  static final Map<String, Future<GeminiTranslationResult>> _cache =
      <String, Future<GeminiTranslationResult>>{};

  Future<GeminiTranslationResult> translate({
    required String text,
    String? sourceLanguage,
    String? targetLanguage,
  }) {
    final key = text.trim();
    if (key.isEmpty) {
      return Future.error(
          const TranslationException('Empty text', statusCode: 400));
    }

    final cached = _cache[key];
    if (cached != null) return cached;

    if (_cache.length >= _maxCacheEntries) {
      _cache.remove(_cache.keys.first); // insertion order → oldest first
    }

    final future = _request(
      text: key,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );
    _cache[key] = future;
    // Evict on failure (this listener also marks the error as handled; the
    // caller still receives it through the returned future).
    future.then<void>((_) {}, onError: (Object _) {
      if (identical(_cache[key], future)) _cache.remove(key);
    });
    return future;
  }

  Future<GeminiTranslationResult> _request({
    required String text,
    String? sourceLanguage,
    String? targetLanguage,
  }) async {
    final config = await AppConfigService.load();
    final endpoint = _buildEndpoint(
      baseUrl: config.backendBaseUrl,
      path: config.geminiTranslationPath,
    );

    final source = sourceLanguage ?? config.defaultSourceLanguage;
    final target = targetLanguage ?? config.defaultTargetLanguage;

    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'text': text,
              // Backend auto-detects when sourceLanguage is omitted.
              if (source.isNotEmpty && source != 'auto')
                'sourceLanguage': source,
              if (target.isNotEmpty) 'targetLanguage': target,
              if (config.geminiModel.isNotEmpty) 'model': config.geminiModel,
            }),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const TranslationException('Translation request timed out');
    } catch (e) {
      throw TranslationException('Network error: $e');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TranslationException(
        'Translation request failed',
        statusCode: response.statusCode,
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const TranslationException('Invalid translation response');
    }
    if (decoded is Map<String, dynamic>) {
      final directParsed = _parseBilingualShape(decoded);
      if (directParsed != null) return directParsed;

      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        final nestedParsed = _parseBilingualShape(data);
        if (nestedParsed != null) return nestedParsed;
      }
    }

    throw const TranslationException(
        'Translation response missing en/am/originalLanguage');
  }

  String _buildEndpoint({required String baseUrl, required String path}) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$normalizedBase$normalizedPath';
  }

  GeminiTranslationResult? _parseBilingualShape(Map<String, dynamic> json) {
    final en = json['en'];
    final am = json['am'];
    final originalLanguage = json['originalLanguage'];

    if (en is String &&
        en.trim().isNotEmpty &&
        am is String &&
        am.trim().isNotEmpty &&
        originalLanguage is String &&
        originalLanguage.trim().isNotEmpty) {
      return GeminiTranslationResult(
        en: en,
        am: am,
        originalLanguage: originalLanguage,
      );
    }

    return null;
  }
}

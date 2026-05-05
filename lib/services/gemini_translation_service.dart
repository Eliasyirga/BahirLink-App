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

class GeminiTranslationService {
  Future<GeminiTranslationResult> translate({
    required String text,
    String? sourceLanguage,
    String? targetLanguage,
  }) async {
    final config = await AppConfigService.load();
    final endpoint = _buildEndpoint(
      baseUrl: config.backendBaseUrl,
      path: config.geminiTranslationPath,
    );

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': text,
        // Backend handles language detection, but we keep optional fields
        // for compatibility if backend still accepts/uses them.
        'sourceLanguage': sourceLanguage ?? config.defaultSourceLanguage,
        'targetLanguage': targetLanguage ?? config.defaultTargetLanguage,
        'model': config.geminiModel,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Translation request failed: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final directParsed = _parseBilingualShape(json);
    if (directParsed != null) {
      return directParsed;
    }

    final data = json['data'];
    if (data is Map<String, dynamic>) {
      final nestedParsed = _parseBilingualShape(data);
      if (nestedParsed != null) {
        return nestedParsed;
      }
    }

    throw Exception('Translation response missing en/am/originalLanguage');
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

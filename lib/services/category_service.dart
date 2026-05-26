import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CategoryService {
  // 🔥 SET TO 'true' to develop locally. SET TO 'false' to use live Render server.
  static const bool useLocalBackup = false;

  static String get baseUrl {
    if (!useLocalBackup) {
      return "https://bahirlink-backend-1.onrender.com/api/categories";
    }
    if (kIsWeb) {
      return "http://localhost:5000/api/categories";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:5000/api/categories";
    } else {
      return "http://localhost:5000/api/categories";
    }
  }

  // ── Name extraction helper ──────────────────────────────────────────────────
  // The backend returns name as { "en": "...", "am": "..." } (parsed object) or
  // a JSON string like '{"en":"...","am":"..."}'. This resolves both forms and
  // returns the display string for the requested language, falling back to the
  // other language if the requested one is empty.
  static String extractName(dynamic raw, {String lang = 'en'}) {
    if (raw == null) return '';

    Map<String, dynamic>? map;

    if (raw is Map) {
      map = Map<String, dynamic>.from(raw);
    } else if (raw is String) {
      final trimmed = raw.trim();
      // Handle double-serialized strings: '"{ … }"'
      String candidate = trimmed;
      if (candidate.startsWith('"') && candidate.endsWith('"')) {
        candidate = candidate.substring(1, candidate.length - 1);
      }
      // Unescape inner escaped quotes
      candidate = candidate.replaceAll(r'\"', '"');
      if (candidate.startsWith('{')) {
        try {
          final parsed = jsonDecode(candidate);
          if (parsed is Map) map = Map<String, dynamic>.from(parsed);
        } catch (_) {}
      }
      // Plain legacy string
      if (map == null) return trimmed;
    }

    if (map == null) return raw.toString();

    final preferred = (map[lang] ?? '').toString().trim();
    if (preferred.isNotEmpty) return preferred;

    // Fallback to the other language
    final fallbackLang = lang == 'en' ? 'am' : 'en';
    final fallback = (map[fallbackLang] ?? '').toString().trim();
    return fallback.isNotEmpty ? fallback : '';
  }

  // ── Normalize a single category item ───────────────────────────────────────
  // Injects a resolved "displayName" field so the UI never has to touch raw
  // name objects.  All other fields are passed through unchanged.
  static Map<String, dynamic> _normalizeCategory(
      Map<String, dynamic> raw, String lang) {
    return {
      ...raw,
      // Resolved display string for the current language
      'displayName': extractName(raw['name'], lang: lang),
    };
  }

  // ── GET CATEGORIES BY EMERGENCY TYPE ───────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getCategories(
      String emergencyTypeId,
      {String lang = 'en'}) async {
    try {
      final Uri url = Uri.parse("$baseUrl/type/$emergencyTypeId").replace(
        queryParameters: {'lang': lang},
      );

      final response = await http.get(url, headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Accept-Language": lang,
      }).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> list =
            (decoded['success'] == true && decoded['data'] is List)
                ? decoded['data'] as List<dynamic>
                : (decoded['data'] as List<dynamic>? ?? []);

        return list
            .whereType<Map<String, dynamic>>()
            .map((item) => _normalizeCategory(item, lang))
            .toList();
      }

      debugPrint("❌ Backend Error: ${response.statusCode} - ${response.body}");
      return [];
    } on SocketException {
      debugPrint("❌ Connection Error: Server is unreachable");
      return [];
    } catch (e) {
      debugPrint("❌ CategoryService Exception: $e");
      return [];
    }
  }

  // ── GET CATEGORIES BY AGENCY ────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getCategoriesByAgency(
      String agencyId,
      {String lang = 'en'}) async {
    try {
      final Uri url = Uri.parse("$baseUrl/by-agency/$agencyId").replace(
        queryParameters: {'lang': lang},
      );

      final response = await http.get(url, headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Accept-Language": lang,
      }).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> list = decoded['data'] as List<dynamic>? ?? [];

        return list
            .whereType<Map<String, dynamic>>()
            .map((item) => _normalizeCategory(item, lang))
            .toList();
      }

      debugPrint("❌ Backend Error: ${response.statusCode} - ${response.body}");
      return [];
    } on SocketException {
      debugPrint("❌ Connection Error: Server is unreachable");
      return [];
    } catch (e) {
      debugPrint("❌ CategoryService Exception: $e");
      return [];
    }
  }
}

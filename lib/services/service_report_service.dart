import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class ServiceReportService {
  // 🔥 SET TO 'true' to develop locally. SET TO 'false' to use live Render server.
  static const bool useLocalBackup = false;

  // ── Base URL ───────────────────────────────────────────────────────────────
  static String get serverUrl {
    if (!useLocalBackup) {
      return "https://bahirlink-backend-1.onrender.com";
    }
    if (kIsWeb) return "http://localhost:5000";
    if (Platform.isAndroid)
      return "http://10.0.2.2:5000"; // Android Emulator address
    return "http://localhost:5000"; // iOS Simulator or Desktop
  }

  // Adjusted to evaluate dynamically from the runtime getter
  String get apiUrl => "$serverUrl/api/service";

  // ── Shared headers ─────────────────────────────────────────────────────────
  static Map<String, String> _headers(String lang) => {
        "Content-Type": "application/json",
        "Accept-Language": lang, // Crucial for localization mapping (en/am)
      };

  // ── URL helper ─────────────────────────────────────────────────────────────
  static String getFullImageUrl(String? partialPath) {
    if (partialPath == null || partialPath.isEmpty) return "";
    if (partialPath.startsWith('http')) return partialPath;
    return "$serverUrl$partialPath";
  }

  // ── Text extraction ────────────────────────────────────────────────────────
  static String extractText(
    dynamic field, {
    String lang = 'en',
    String fallback = 'N/A',
  }) {
    if (field == null) return fallback;

    if (field is String) {
      final t = field.trim();
      if (t.startsWith('{') && t.endsWith('}')) {
        try {
          final decoded = json.decode(t);
          if (decoded is Map)
            return extractText(decoded, lang: lang, fallback: fallback);
        } catch (_) {}
      }
      return t.isEmpty ? fallback : t;
    }

    if (field is Map) {
      // 1. Prefer the requested locale.
      final langVal = field[lang];
      if (langVal != null && langVal.toString().trim().isNotEmpty) {
        return langVal.toString();
      }

      // 2. Fall back to English.
      if (lang != 'en') {
        final enVal = field['en'];
        if (enVal != null && enVal.toString().trim().isNotEmpty) {
          return enVal.toString();
        }
      }

      // 3. Accept any named key as a last resort
      for (final key in ['name', 'title', 'label']) {
        final v = field[key];
        if (v != null && v.toString().trim().isNotEmpty) {
          return v.toString();
        }
      }

      // 4. Return whatever non-empty value exists.
      for (final v in field.values) {
        if (v != null && v.toString().trim().isNotEmpty) {
          return v.toString();
        }
      }

      return fallback;
    }

    final str = field.toString();
    return str.trim().isEmpty ? fallback : str;
  }

  // ── CREATE ─────────────────────────────────────────────────────────────────
  Future<bool> reportService({
    required String userId,
    required String name,
    required String description,
    required String subdivision,
    required String serviceTypeId,
    required String serviceCategoryId,
    File? imageFile,
    double? lat,
    double? lng,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      request.fields['citizenId'] = userId;
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['subdivision'] = subdivision;
      request.fields['serviceTypeId'] = serviceTypeId;
      request.fields['serviceCategoryId'] = serviceCategoryId;

      if (lat != null) request.fields['latitude'] = lat.toString();
      if (lng != null) request.fields['longitude'] = lng.toString();

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          filename: basename(imageFile.path),
        ));
      }

      // 60-second window handles potential server spin-up overhead during multi-part stream uploads
      final streamed =
          await request.send().timeout(const Duration(seconds: 60));
      return streamed.statusCode == 201;
    } catch (e) {
      debugPrint("reportService error: $e");
      return false;
    }
  }

  // ── READ (list) ────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getUserServices(
    String userId, {
    String lang = 'en',
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$apiUrl/user/$userId'),
            headers: _headers(lang),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        debugPrint(
            "Server error during getUserServices: ${response.statusCode}");
        return [];
      }

      final dynamic decoded = json.decode(response.body);
      final List<dynamic> raw = switch (decoded) {
        List() => decoded,
        Map(containsKey: _) => (decoded as Map)['data'] as List? ?? [],
        _ => [],
      };

      return raw.map(_normalizeItem).toList();
    } on SocketException {
      debugPrint("❌ ServiceReportService: Server unreachable.");
      return [];
    } catch (e) {
      debugPrint("getUserServices error: $e");
      return [];
    }
  }

  // ── DELETE ─────────────────────────────────────────────────────────────────
  Future<bool> deleteService(int serviceId) async {
    try {
      final response = await http
          .delete(Uri.parse('$apiUrl/$serviceId'))
          .timeout(const Duration(seconds: 30));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("deleteService error: $e");
      return false;
    }
  }

  // ── Normalization ──────────────────────────────────────────────────────────
  static Map<String, dynamic> _normalizeItem(dynamic raw) {
    if (raw is! Map) return {};
    final item = Map<String, dynamic>.from(raw);

    for (final key in ['name', 'description', 'subdivision', 'street']) {
      if (item.containsKey(key)) item[key] = _decodeIfJson(item[key]);
    }

    for (final key in [
      'serviceType',
      'serviceCategory',
      'street',
      'Kebele',
      'kebele',
      'lastSeenLocation',
    ]) {
      if (!item.containsKey(key)) continue;
      final val = _decodeIfJson(item[key]);
      if (val is Map) {
        final nested = Map<String, dynamic>.from(val);
        if (nested.containsKey('name')) {
          nested['name'] = _decodeIfJson(nested['name']);
        }
        if (nested.containsKey('description')) {
          nested['description'] = _decodeIfJson(nested['description']);
        }
        item[key] = nested;
      } else {
        item[key] = val;
      }
    }

    return item;
  }

  static dynamic _decodeIfJson(dynamic value) {
    if (value is! String) return value;
    final t = value.trim();
    if (!t.startsWith('{') || !t.endsWith('}')) return value;
    try {
      final decoded = json.decode(t);
      if (decoded is String) {
        final inner = decoded.trim();
        if (inner.startsWith('{') && inner.endsWith('}')) {
          try {
            final inner2 = json.decode(inner);
            if (inner2 is Map) return inner2;
          } catch (_) {}
        }
        return decoded;
      }
      if (decoded is Map) return decoded;
    } catch (_) {}
    return value;
  }
}

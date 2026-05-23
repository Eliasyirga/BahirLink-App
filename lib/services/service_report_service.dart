import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class ServiceReportService {
  // ── Base URL ───────────────────────────────────────────────────────────────
  static String get serverUrl {
    if (kIsWeb) return "http://localhost:5000";
    if (Platform.isAndroid) return "http://10.0.2.2:5000";
    return "http://localhost:5000";
  }

  final String apiUrl = "$serverUrl/api/service";

  // ── Shared headers ─────────────────────────────────────────────────────────
  static Map<String, String> _headers(String lang) => {
        "Content-Type": "application/json",
        "Accept-Language": lang,
      };

  // ── URL helper ─────────────────────────────────────────────────────────────
  static String getFullImageUrl(String? partialPath) {
    if (partialPath == null || partialPath.isEmpty) return "";
    if (partialPath.startsWith('http')) return partialPath;
    return "$serverUrl$partialPath";
  }

  // ── Text extraction ────────────────────────────────────────────────────────
  // FIX: Language keys (lang, 'en') are checked FIRST so that a bilingual
  //      map like {en: "Water Supply", am: "የውሃ አቅርቦት"} is resolved to the
  //      correct locale string instead of falling through to a missing
  //      'name'/'title'/'label' key.
  static String extractText(
    dynamic field, {
    String lang = 'en',
    String fallback = 'N/A',
  }) {
    if (field == null) return fallback;

    if (field is String) {
      // The string might still be a JSON-encoded bilingual map that the
      // normalizer missed (e.g. nested inside an unexpected field).
      final t = field.trim();
      if (t.startsWith('{') && t.endsWith('}')) {
        try {
          final decoded = json.decode(t);
          if (decoded is Map) return extractText(decoded, lang: lang, fallback: fallback);
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

      // 3. Accept any named key ('name', 'title', 'label') as a last resort
      //    (e.g. non-translated legacy records).
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

      request.fields['citizenId']         = userId;
      request.fields['name']              = name;
      request.fields['description']       = description;
      request.fields['subdivision']       = subdivision;
      request.fields['serviceTypeId']     = serviceTypeId;
      request.fields['serviceCategoryId'] = serviceCategoryId;

      if (lat != null) request.fields['latitude']  = lat.toString();
      if (lng != null) request.fields['longitude'] = lng.toString();

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          filename: basename(imageFile.path),
        ));
      }

      final response = await request.send();
      return response.statusCode == 201;
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
    final response = await http.get(
      Uri.parse('$apiUrl/user/$userId'),
      headers: _headers(lang),
    );

    if (response.statusCode != 200) {
      throw Exception("Server error: ${response.statusCode}");
    }

    final dynamic decoded = json.decode(response.body);
    final List<dynamic> raw = switch (decoded) {
      List()              => decoded,
      Map(containsKey: _) => (decoded as Map)['data'] as List? ?? [],
      _                   => [],
    };

    return raw.map(_normalizeItem).toList();
  }

  // ── DELETE ─────────────────────────────────────────────────────────────────
  Future<bool> deleteService(int serviceId) async {
    try {
      final response = await http.delete(Uri.parse('$apiUrl/$serviceId'));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("deleteService error: $e");
      return false;
    }
  }

  // ── Normalization ──────────────────────────────────────────────────────────
  // Decodes any double-stringified JSON fields so that extractText always
  // receives either a plain String or a Map — never a JSON-encoded string.
  static Map<String, dynamic> _normalizeItem(dynamic raw) {
    if (raw is! Map) return {};
    final item = Map<String, dynamic>.from(raw);

    // Top-level text fields.
    for (final key in ['name', 'description', 'subdivision', 'street']) {
      if (item.containsKey(key)) item[key] = _decodeIfJson(item[key]);
    }

    // Nested objects whose 'name' may also be a bilingual map.
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
        // FIX: decode nested 'name' so it becomes a Map{en,am}, not a string.
        if (nested.containsKey('name')) {
          nested['name'] = _decodeIfJson(nested['name']);
        }
        // Also decode nested 'description' for completeness.
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
      // Handle double-stringified JSON (a string whose value is also JSON).
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
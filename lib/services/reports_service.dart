import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;

class ReportsService {
  // ── Base URL ───────────────────────────────────────────────────────────────
  static String get serverUrl {
    if (kIsWeb) return "http://localhost:5000";
    if (Platform.isAndroid) return "http://10.0.2.2:5000";
    return "http://localhost:5000";
  }

  static String get baseUrl => "$serverUrl/api";

  // ── Shared headers ─────────────────────────────────────────────────────────
  static Map<String, String> _headers({String lang = 'en', String? token}) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Accept-Language': lang,
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // ── URL helper ─────────────────────────────────────────────────────────────
  static String getFullImageUrl(String? partialPath) {
    if (partialPath == null || partialPath.isEmpty) return '';
    if (partialPath.startsWith('http')) return partialPath;
    return '$serverUrl$partialPath';
  }

  // ── Text extraction ────────────────────────────────────────────────────────
  /// Pulls a localised string from whatever shape the API returns:
  ///   • `{"en": "Fire", "am": "እሳት"}` → picks [lang], then 'en', then any value
  ///   • `"Fire"`                        → returned as-is
  ///   • `null`                          → [fallback]
  static String extractText(
    dynamic field, {
    String lang = 'en',
    String fallback = 'N/A',
  }) {
    if (field == null) return fallback;
    if (field is String) return field.trim().isEmpty ? fallback : field;
    if (field is Map) {
      for (final key in [lang, 'en']) {
        final v = field[key];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString();
      }
      for (final v in field.values) {
        if (v != null && v.toString().trim().isNotEmpty) return v.toString();
      }
      return fallback;
    }
    final str = field.toString();
    return str.trim().isEmpty ? fallback : str;
  }

  // ── Fetch emergencies + categories in parallel, enrich with names ──────────
  ///
  /// Strategy (mirrors the original _localise approach):
  ///   1. Fetch raw emergencies and ALL categories in parallel.
  ///   2. Build a lookup map: categoryId → category doc.
  ///   3. For each emergency resolve its category by whatever field the API
  ///      uses (`categoryId` string, `categoryId` object, or `category` object).
  ///   4. Write resolved, lang-aware strings into `categoryName` and `typeName`
  ///      so the page just reads those flat fields — no further digging needed.
  static Future<List<Map<String, dynamic>>> fetchUserEmergencies(
    String id, {
    String lang = 'en',
    String? token,
    bool isGuest = false,
  }) async {
    // ── 1. Parallel fetch ──────────────────────────────────────────────────
    final results = await Future.wait([
      http.get(
        Uri.parse('$baseUrl/emergencies/$id${isGuest ? '?guestId=true' : ''}'),
        headers: _headers(lang: lang, token: token),
      ),
      http.get(
        Uri.parse('$baseUrl/categories'),
        headers: _headers(lang: lang, token: token),
      ),
    ]);

    final emergencyResp = results[0];
    final categoryResp  = results[1];

    if (emergencyResp.statusCode != 200) {
      throw Exception('Failed to load emergencies: ${emergencyResp.body}');
    }

    // ── 2. Decode emergencies ──────────────────────────────────────────────
    final dynamic eDec = jsonDecode(emergencyResp.body);
    final List<dynamic> rawEmergencies = switch (eDec) {
      List() => eDec,
      Map()  => (eDec as Map)['data'] as List? ?? [],
      _      => [],
    };

    // ── 3. Build category lookup map  id → category doc ───────────────────
    final Map<String, Map<String, dynamic>> catById = {};

    if (categoryResp.statusCode == 200) {
      final dynamic cDec = jsonDecode(categoryResp.body);
      final List<dynamic> rawCats = cDec is List
          ? cDec
          : ((cDec as Map)['data'] as List? ?? []);

      for (final c in rawCats) {
        if (c is! Map) continue;
        final catId = _extractId(c['id'] ?? c['_id']);
        if (catId != null) {
          catById[catId] = Map<String, dynamic>.from(c);
        }
      }
    }

    debugPrint('📦 emergencies=${rawEmergencies.length} '
        'categories=${catById.length}');

    // ── 4. Normalise + enrich each emergency ───────────────────────────────
    return rawEmergencies
        .whereType<Map>()
        .map((raw) => _enrichEmergency(
              Map<String, dynamic>.from(raw),
              catById,
              lang,
            ))
        .where((m) => m.isNotEmpty)
        .toList();
  }

  // ── Enrich a single emergency with resolved category/type names ────────────
  static Map<String, dynamic> _enrichEmergency(
    Map<String, dynamic> item,
    Map<String, Map<String, dynamic>> catById,
    String lang,
  ) {
    // Decode stringified-JSON description
    if (item.containsKey('description')) {
      item['description'] = _decodeIfJson(item['description']);
    }

    // Decode other nested objects the detail screen may need
    for (final key in ['location', 'kebele', 'Kebele', 'lastSeenLocation']) {
      if (item.containsKey(key)) {
        item[key] = _decodeIfJson(item[key]);
      }
    }

    // ── Resolve the category document ──────────────────────────────────────
    // The API may send any of:
    //   A) categoryId: "abc123"                    (bare string ID)
    //   B) categoryId: { id, name, emergencyType } (populated object)
    //   C) category:   { id, name, emergencyType } (populated under different key)
    Map<String, dynamic>? catDoc;

    final rawCatField = item['categoryId'] ?? item['category'];
    final decoded     = _decodeIfJson(rawCatField);

    if (decoded is Map) {
      // Shape B or C — already a populated object
      catDoc = Map<String, dynamic>.from(decoded);
      if (catDoc.containsKey('name')) {
        catDoc['name'] = _decodeIfJson(catDoc['name']);
      }
    } else if (decoded is String && decoded.isNotEmpty) {
      // Shape A — bare ID, look up from the categories list we fetched
      catDoc = catById[decoded];
    }

    // ── Write flat resolved fields the page reads directly ─────────────────
    if (catDoc != null) {
      item['categoryName'] = extractText(catDoc['name'], lang: lang);

      final typeRaw = _decodeIfJson(catDoc['emergencyType']);
      if (typeRaw is Map) {
        final typeMap = Map<String, dynamic>.from(typeRaw);
        if (typeMap.containsKey('name')) {
          typeMap['name'] = _decodeIfJson(typeMap['name']);
        }
        item['typeName'] = extractText(typeMap['name'], lang: lang);
      } else if (typeRaw is String && typeRaw.isNotEmpty) {
        item['typeName'] = typeRaw;
      }

      // Keep normalised category doc for detail pages
      item['category'] = catDoc;
    }

    // ── Fallback: emergencyType may also arrive as a top-level field ────────
    if (item['typeName'] == null || item['typeName'].toString().isEmpty) {
      final typeRaw = _decodeIfJson(item['emergencyType']);
      if (typeRaw is Map) {
        final typeMap = Map<String, dynamic>.from(typeRaw);
        if (typeMap.containsKey('name')) {
          typeMap['name'] = _decodeIfJson(typeMap['name']);
        }
        item['typeName']      = extractText(typeMap['name'], lang: lang);
        item['emergencyType'] = typeMap;
      }
    }

    debugPrint('✅ id=${item['id'] ?? item['_id']} '
        '| categoryName=${item['categoryName']} '
        '| typeName=${item['typeName']}');

    return item;
  }

  // ── Fetch Categories (standalone — used by other screens) ─────────────────
  static Future<List<Map<String, dynamic>>> fetchCategories({
    String lang = 'en',
    String? token,
  }) async {
    final uri      = Uri.parse('$baseUrl/categories');
    final response = await http.get(uri, headers: _headers(lang: lang, token: token));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> raw =
          decoded is List ? decoded : ((decoded as Map)['data'] as List? ?? []);
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    throw Exception('Failed to load categories');
  }

  // ── Fetch Emergency Types ──────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchEmergencyTypes({
    String lang = 'en',
    String? token,
  }) async {
    final uri      = Uri.parse('$baseUrl/emergencyType');
    final response = await http.get(uri, headers: _headers(lang: lang, token: token));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return List<Map<String, dynamic>>.from(decoded);
      return List<Map<String, dynamic>>.from(
          (decoded as Map)['emergencyTypes'] ?? []);
    }

    throw Exception('Failed to load emergency types');
  }

  // ── Update Emergency ───────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> updateEmergency(
    String userOrGuestId,
    String emergencyId,
    Map<String, dynamic> updatedData, {
    File? file,
    Uint8List? webBytes,
    String? fileName,
    String lang = 'en',
    String? token,
    bool isGuest = false,
  }) async {
    final uri     = Uri.parse('$baseUrl/emergencies/$userOrGuestId/$emergencyId');
    final request = http.MultipartRequest('PUT', uri);

    request.headers.addAll(_headers(lang: lang, token: token));
    if (isGuest) request.fields['guestId'] = userOrGuestId;

    updatedData.forEach((key, value) {
      if (value != null) {
        request.fields[key] = (value is Map || value is List)
            ? jsonEncode(value)
            : value.toString();
      }
    });

    if (kIsWeb && webBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
          'media', webBytes, filename: fileName ?? 'upload.jpg'));
    } else if (!kIsWeb && file != null) {
      request.files.add(await http.MultipartFile.fromPath('media', file.path));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return Map<String, dynamic>.from((decoded as Map)['data'] ?? decoded);
    }

    throw Exception('Update failed: ${response.body}');
  }

  // ── Delete Emergency ───────────────────────────────────────────────────────
  static Future<void> deleteEmergency(
    String userOrGuestId,
    String emergencyId, {
    String lang = 'en',
    String? token,
    bool isGuest = false,
  }) async {
    final uri      = Uri.parse('$baseUrl/emergencies/$userOrGuestId/$emergencyId');
    final response = await http.delete(
      uri,
      headers: _headers(lang: lang, token: token),
      body: isGuest ? jsonEncode({'guestId': userOrGuestId}) : null,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete emergency: ${response.body}');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  static String? _extractId(dynamic field) {
    if (field == null) return null;
    if (field is String) return field.trim().isEmpty ? null : field;
    if (field is Map) {
      return field['id']?.toString() ?? field['_id']?.toString();
    }
    return field.toString();
  }

  static dynamic _decodeIfJson(dynamic value) {
    if (value is! String) return value;
    final t = value.trim();
    if ((!t.startsWith('{') || !t.endsWith('}')) &&
        (!t.startsWith('[') || !t.endsWith(']'))) return value;
    try {
      return jsonDecode(t);
    } catch (_) {
      return value;
    }
  }
}
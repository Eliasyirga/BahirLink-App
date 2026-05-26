import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;

class ReportsService {
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

  static String get baseUrl => "$serverUrl/api";

  // ── Shared headers ─────────────────────────────────────────────────────────
  static Map<String, String> _headers({String lang = 'en', String? token}) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Accept-Language': lang, // Crucial for localization mapping (en/am)
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // ── URL helper ─────────────────────────────────────────────────────────────
  static String getFullImageUrl(String? partialPath) {
    if (partialPath == null || partialPath.isEmpty) return '';
    if (partialPath.startsWith('http')) return partialPath;
    return '$serverUrl$partialPath';
  }

  // ── Text extraction ────────────────────────────────────────────────────────
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
  static Future<List<Map<String, dynamic>>> fetchUserEmergencies(
    String id, {
    String lang = 'en',
    String? token,
    bool isGuest = false,
  }) async {
    // ── 1. Parallel fetch with expanded timeouts for Render free-tier cold-starts ─────────────────────────
    final results = await Future.wait([
      http
          .get(
            Uri.parse(
                '$baseUrl/emergencies/$id${isGuest ? '?guestId=true' : ''}'),
            headers: _headers(lang: lang, token: token),
          )
          .timeout(const Duration(seconds: 60)),
      http
          .get(
            Uri.parse('$baseUrl/categories'),
            headers: _headers(lang: lang, token: token),
          )
          .timeout(const Duration(seconds: 60)),
    ]);

    final emergencyResp = results[0];
    final categoryResp = results[1];

    if (emergencyResp.statusCode != 200) {
      throw Exception('Failed to load emergencies: ${emergencyResp.body}');
    }

    // ── 2. Decode emergencies ──────────────────────────────────────────────
    final dynamic eDec = jsonDecode(emergencyResp.body);
    final List<dynamic> rawEmergencies = switch (eDec) {
      List() => eDec,
      Map() => (eDec as Map)['data'] as List? ?? [],
      _ => [],
    };

    // ── 3. Build category lookup map  id → category doc ───────────────────
    final Map<String, Map<String, dynamic>> catById = {};

    if (categoryResp.statusCode == 200) {
      final dynamic cDec = jsonDecode(categoryResp.body);
      final List<dynamic> rawCats =
          cDec is List ? cDec : ((cDec as Map)['data'] as List? ?? []);

      for (final c in rawCats) {
        if (c is! Map) continue;
        final catId = _extractId(c['id'] ?? c['_id']);
        if (catId != null) {
          catById[catId] = Map<String, dynamic>.from(c);
        }
      }
    }

    debugPrint(
        '📦 emergencies=${rawEmergencies.length} categories=${catById.length}');

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
    if (item.containsKey('description')) {
      item['description'] = _decodeIfJson(item['description']);
    }

    for (final key in ['location', 'kebele', 'Kebele', 'lastSeenLocation']) {
      if (item.containsKey(key)) {
        item[key] = _decodeIfJson(item[key]);
      }
    }

    Map<String, dynamic>? catDoc;
    final rawCatField = item['categoryId'] ?? item['category'];
    final decoded = _decodeIfJson(rawCatField);

    if (decoded is Map) {
      catDoc = Map<String, dynamic>.from(decoded);
      if (catDoc.containsKey('name')) {
        catDoc['name'] = _decodeIfJson(catDoc['name']);
      }
    } else if (decoded is String && decoded.isNotEmpty) {
      catDoc = catById[decoded];
    }

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

      item['category'] = catDoc;
    }

    if (item['typeName'] == null || item['typeName'].toString().isEmpty) {
      final typeRaw = _decodeIfJson(item['emergencyType']);
      if (typeRaw is Map) {
        final typeMap = Map<String, dynamic>.from(typeRaw);
        if (typeMap.containsKey('name')) {
          typeMap['name'] = _decodeIfJson(typeMap['name']);
        }
        item['typeName'] = extractText(typeMap['name'], lang: lang);
        item['emergencyType'] = typeMap;
      }
    }

    debugPrint('✅ id=${item['id'] ?? item['_id']} '
        '| categoryName=${item['categoryName']} '
        '| typeName=${item['typeName']}');

    return item;
  }

  // ── Fetch Categories ───────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchCategories({
    String lang = 'en',
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/categories');
      final response = await http
          .get(uri, headers: _headers(lang: lang, token: token))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> raw = decoded is List
            ? decoded
            : ((decoded as Map)['data'] as List? ?? []);
        return raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      throw Exception('Failed to load categories: ${response.statusCode}');
    } on SocketException {
      debugPrint("❌ ReportsService.fetchCategories: Server unreachable.");
      return [];
    }
  }

  // ── Fetch Emergency Types ──────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchEmergencyTypes({
    String lang = 'en',
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/emergencyType');
      final response = await http
          .get(uri, headers: _headers(lang: lang, token: token))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return List<Map<String, dynamic>>.from(decoded);
        return List<Map<String, dynamic>>.from(
            (decoded as Map)['emergencyTypes'] ?? decoded['data'] ?? []);
      }
      throw Exception('Failed to load emergency types: ${response.statusCode}');
    } on SocketException {
      debugPrint("❌ ReportsService.fetchEmergencyTypes: Server unreachable.");
      return [];
    }
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
    final uri = Uri.parse('$baseUrl/emergencies/$userOrGuestId/$emergencyId');
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
      request.files.add(http.MultipartFile.fromBytes('media', webBytes,
          filename: fileName ?? 'upload.jpg'));
    } else if (!kIsWeb && file != null) {
      request.files.add(await http.MultipartFile.fromPath('media', file.path));
    }

    // 60-second window allocated for concurrent text and file payload streams
    final streamed = await request.send().timeout(const Duration(seconds: 60));
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
    final uri = Uri.parse('$baseUrl/emergencies/$userOrGuestId/$emergencyId');
    final response = await http
        .delete(
          uri,
          headers: _headers(lang: lang, token: token),
          body: isGuest ? jsonEncode({'guestId': userOrGuestId}) : null,
        )
        .timeout(const Duration(seconds: 30));

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

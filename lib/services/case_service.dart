import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CaseService {
  // 🔥 SET TO 'true' to develop locally. SET TO 'false' to use live Render server.
  static const bool useLocalBackup = false;

  // 🌍 Dynamic Origin URL Router
  static String get _host {
    if (!useLocalBackup) {
      return "https://bahirlink-backend-1.onrender.com";
    }
    if (kIsWeb) {
      return "http://localhost:5000";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:5000"; // Android Emulator address
    } else {
      return "http://localhost:5000"; // iOS Simulator or Desktop
    }
  }

  static String get _baseUrl => "$_host/api/cases";

  // ── Shared headers ──────────────────────────────────────────────────────────
  static Map<String, String> _headers(String lang) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Accept-Language': lang,
      };

  // ── GET ALL CASES ───────────────────────────────────────────────────────────
  static Future<List<dynamic>> getAllCases({String lang = 'en'}) async {
    try {
      final url = Uri.parse(_baseUrl).replace(queryParameters: {'lang': lang});

      final response = await http
          .get(url, headers: _headers(lang))
          .timeout(const Duration(seconds: 60)); // Extended for Render spin-up

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['data'] is List) {
          return (data['data'] as List).where((c) {
            final s = (c['status'] ?? '').toString().toLowerCase();
            return s != 'rejected' && s != 'resolved';
          }).toList();
        }
        return [];
      }
      debugPrint('❌ getAllCases ${response.statusCode}: ${response.body}');
      return [];
    } on SocketException {
      debugPrint('❌ getAllCases: server unreachable');
      return [];
    } catch (e) {
      debugPrint('❌ getAllCases exception: $e');
      return [];
    }
  }

  // ── GET CASE BY ID ──────────────────────────────────────────────────────────
  static Future<dynamic> getCaseById({
    required String id,
    String lang = 'en',
  }) async {
    try {
      final url =
          Uri.parse('$_baseUrl/$id').replace(queryParameters: {'lang': lang});

      final response = await http
          .get(url, headers: _headers(lang))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null)
          return data['data'];
        return data;
      }
      debugPrint('❌ getCaseById ${response.statusCode}: ${response.body}');
      return null;
    } on SocketException {
      debugPrint('❌ getCaseById: server unreachable');
      return null;
    } catch (e) {
      debugPrint('❌ getCaseById exception: $e');
      return null;
    }
  }

  // ── CREATE CASE ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> createCase({
    required String fullName,
    required String caseTypeId,
    required String responderTeamId,
    String description = '',
    String distinctiveFeatures = '',
    String? gender,
    String priority = 'medium',
    String? lastSeenDate,
    String? contactInfo,
    bool isDangerous = false,
    int? age,
    int? height,
    int? weight,
    double reward = 0,
    String? lastSeenLocationId,
    File? mediaFile,
    String lang = 'en',
  }) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {'lang': lang});

      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Accept': 'application/json',
          'Accept-Language': lang,
        })
        ..fields['fullName'] = fullName
        ..fields['description'] = description
        ..fields['distinctiveFeatures'] = distinctiveFeatures
        ..fields['caseTypeId'] = caseTypeId
        ..fields['responderTeamId'] = responderTeamId
        ..fields['priority'] = priority
        ..fields['isDangerous'] = isDangerous.toString()
        ..fields['reward'] = reward.toString();

      if (gender != null) request.fields['gender'] = gender;
      if (lastSeenDate != null) request.fields['lastSeenDate'] = lastSeenDate;
      if (contactInfo != null) request.fields['contactInfo'] = contactInfo;
      if (lastSeenLocationId != null)
        request.fields['lastSeenLocationId'] = lastSeenLocationId;
      if (age != null) request.fields['age'] = age.toString();
      if (height != null) request.fields['height'] = height.toString();
      if (weight != null) request.fields['weight'] = weight.toString();

      if (mediaFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'media', // Matches Multer upload parameter on backend
          mediaFile.path,
        ));
      }

      // 60-second limit allocated for data stream uploading over mobile connections
      final streamed =
          await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) return data['data'];
      }
      debugPrint('❌ createCase ${response.statusCode}: ${response.body}');
      return null;
    } on SocketException {
      debugPrint('❌ createCase: server unreachable');
      return null;
    } catch (e) {
      debugPrint('❌ createCase exception: $e');
      return null;
    }
  }

  // ── UPDATE CASE STATUS ──────────────────────────────────────────────────────
  static Future<bool> updateCaseStatus({
    required String id,
    required String status,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/$id/status');

      final response = await http
          .patch(
            url,
            headers: _headers('en'),
            body: jsonEncode({'status': status}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['success'] == true;
      }
      debugPrint('❌ updateCaseStatus ${response.statusCode}: ${response.body}');
      return false;
    } on SocketException {
      debugPrint('❌ updateCaseStatus: server unreachable');
      return false;
    } catch (e) {
      debugPrint('❌ updateCaseStatus exception: $e');
      return false;
    }
  }

  // ── DELETE CASE ─────────────────────────────────────────────────────────────
  static Future<bool> deleteCase(String id) async {
    try {
      final url = Uri.parse('$_baseUrl/$id');

      final response = await http
          .delete(url, headers: _headers('en'))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['success'] == true;
      }
      debugPrint('❌ deleteCase ${response.statusCode}: ${response.body}');
      return false;
    } on SocketException {
      debugPrint('❌ deleteCase: server unreachable');
      return false;
    } catch (e) {
      debugPrint('❌ deleteCase exception: $e');
      return false;
    }
  }

  // ── HELPERS ─────────────────────────────────────────────────────────────────

  /// Dynamically appends current active host mapping onto incoming media files
  static String mediaUrl(String? serverPath) {
    if (serverPath == null || serverPath.isEmpty) return '';
    if (serverPath.startsWith('http')) return serverPath;
    return '$_host$serverPath';
  }

  static String extractKebele(
    dynamic caseData, {
    String fallback = 'Location Not Set',
  }) {
    final loc = caseData['lastSeenLocation'];
    if (loc is Map) {
      final name = loc['name']?.toString() ?? '';
      if (name.isNotEmpty) return name;

      final nested = loc['Kebele'] ?? loc['kebele'];
      if (nested is Map) {
        final nName = nested['name']?.toString() ?? '';
        if (nName.isNotEmpty) return nName;
      }
    }

    final kebele = caseData['Kebele'] ?? caseData['kebele'];
    if (kebele is Map) {
      final name = kebele['name']?.toString() ?? '';
      if (name.isNotEmpty) return name;
    }

    for (final key in ['kebele_name', 'kebeleId', 'kebele_id', 'KebeleId']) {
      final val = caseData[key]?.toString() ?? '';
      if (val.isNotEmpty) return val;
    }

    return fallback;
  }

  static String getDisplayText(dynamic value) =>
      value == null ? 'N/A' : value.toString();
}

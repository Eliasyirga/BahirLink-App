import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/emergency_report_model.dart';

class UserEmergencyService {
  // ─── Base URL ──────────────────────────────────────────────────────────────
  static String get baseUrl {
    if (kIsWeb) return "http://localhost:5000/api";
    if (Platform.isAndroid) return "http://10.0.2.2:5000/api";
    return "http://localhost:5000/api";
  }

  // ─── Shared headers ────────────────────────────────────────────────────────
  /// Mirrors EmergencyService._headers() — always sends Accept-Language so the
  /// backend's autoTranslate() detects the input language and persists both
  /// { en, am } regardless of which language the user typed in.
  static Map<String, String> _headers(String lang) => {
        'Accept': 'application/json',
        'Accept-Language': lang,
      };

  // ─── Get stored user ID ────────────────────────────────────────────────────
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final rawId = prefs.get("userId");
    if (rawId is int) return rawId;
    if (rawId is String) return int.tryParse(rawId);
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SEND USER EMERGENCY
  //
  // [lang] must be the current app locale ('en' or 'am'), loaded from
  // SharedPreferences with key 'language_code' — the same key the dashboard
  // language switcher writes to.  It is forwarded as the Accept-Language
  // header so the backend returns localised responses and autoTranslate()
  // knows the caller's locale context.
  // ══════════════════════════════════════════════════════════════════════════
  static Future<bool> sendUserEmergency({
    required int userId,
    required EmergencyReportModel report,
    double? latitude,
    double? longitude,
    Uint8List? mediaBytes,
    File? mediaFile,
    String? mediaName,
    String lang = 'en',       // ← new: mirrors EmergencyService pattern
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("accessToken");

      if (token == null) {
        debugPrint("❌ No access token found");
        return false;
      }

      final uri = Uri.parse("$baseUrl/emergencies/users/$userId");
      final request = http.MultipartRequest("POST", uri);

      // Set Accept-Language + Authorization headers
      request.headers.addAll({
        ..._headers(lang),
        'Authorization': 'Bearer $token',
      });

      // ── Fields ─────────────────────────────────────────────────────────────
      final data = report.toJsonForUser();

      // Map 'kebele' from model → 'kebeleId' expected by backend
      request.fields['kebeleId']   = report.kebele?.toString() ?? "";
      request.fields['subdivision'] = report.subdivision ?? "";

      // Add remaining fields, skipping the ones already set above
      data.forEach((key, value) {
        if (value != null && key != 'kebele' && key != 'subdivision') {
          request.fields[key] = value.toString();
        }
      });

      if (latitude != null)  request.fields["latitude"]  = latitude.toString();
      if (longitude != null) request.fields["longitude"] = longitude.toString();

      // ── Media ──────────────────────────────────────────────────────────────
      if (kIsWeb) {
        if (mediaBytes != null && mediaName != null) {
          _addBytesFile(request, mediaBytes, mediaName);
        }
      } else if (mediaFile != null) {
        await _addPathFile(request, mediaFile);
      }

      debugPrint("🚀 Requesting: POST $uri");
      debugPrint("📦 Payload: ${request.fields}");
      debugPrint("🌐 Lang header: $lang");

      final streamed  = await request.send();
      final response  = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("🎉 Emergency report successful");
        return true;
      } else {
        debugPrint("❌ Server Error ${response.statusCode}: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ UserEmergencyService Exception: $e");
      return false;
    }
  }

  // ── Private media helpers ──────────────────────────────────────────────────
  // Mirrors EmergencyService._addBytesFile / _addPathFile exactly.

  static void _addBytesFile(
      http.MultipartRequest request, Uint8List bytes, String fileName) {
    final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
    final parts    = mimeType.split('/');
    request.fields['mediaType'] = parts.first == 'video' ? 'video' : 'photo';
    request.files.add(http.MultipartFile.fromBytes(
      'media',
      bytes,
      filename:    fileName,
      contentType: MediaType(parts[0], parts[1]),
    ));
  }

  static Future<void> _addPathFile(
      http.MultipartRequest request, File file) async {
    final fileName = path.basename(file.path);
    final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
    final parts    = mimeType.split('/');
    request.fields['mediaType'] = parts.first == 'video' ? 'video' : 'photo';
    request.files.add(await http.MultipartFile.fromPath(
      'media',
      file.path,
      contentType: MediaType(parts[0], parts[1]),
    ));
  }
}
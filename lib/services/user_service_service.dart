import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/service_report_model.dart';

class UserServiceService {
  // 🔥 SET TO 'true' to develop locally. SET TO 'false' to use live Render server.
  static const bool useLocalBackup = false;

  // ─── Base URL ──────────────────────────────────────────────────────────────
  static String get baseUrl {
    if (!useLocalBackup) {
      return "https://bahirlink-backend-1.onrender.com/api";
    }
    if (kIsWeb) return "http://localhost:5000/api";
    if (Platform.isAndroid)
      return "http://10.0.2.2:5000/api"; // Android Emulator address
    return "http://localhost:5000/api"; // iOS Simulator or Desktop
  }

  // ─── Shared headers ────────────────────────────────────────────────────────
  static Map<String, String> _headers(String lang) => {
        'Accept': 'application/json',
        'Accept-Language': lang, // Crucial for localization mapping (en/am)
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
  // SEND USER SERVICE REQUEST
  // ══════════════════════════════════════════════════════════════════════════
  static Future<bool> sendUserService({
    required int userId,
    required ServiceReportModel report,
    Uint8List? mediaBytes,
    File? mediaFile,
    String? mediaName,
    String lang = 'en',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("accessToken");

      if (token == null) {
        debugPrint("❌ UserService Error: Access token missing");
        return false;
      }

      final uri = Uri.parse("$baseUrl/service/create/$userId");
      final request = http.MultipartRequest("POST", uri);

      request.headers.addAll({
        ..._headers(lang),
        'Authorization': 'Bearer $token',
      });

      request.fields['name'] = "Service Req: ${report.subdivision}";
      request.fields['description'] = report.description;
      request.fields['serviceTypeId'] = report.serviceTypeId;
      request.fields['serviceCategoryId'] = report.serviceCategoryId;
      request.fields['kebeleId'] = report.kebeleId.toString();
      request.fields['subdivision'] = report.subdivision;
      request.fields['street'] = report.street;

      if (report.latitude != null) {
        request.fields['latitude'] = report.latitude.toString();
      }
      if (report.longitude != null) {
        request.fields['longitude'] = report.longitude.toString();
      }

      request.fields['time'] =
          report.time.toIso8601String().split('T')[1].split('.')[0];

      if (kIsWeb) {
        if (mediaBytes != null && mediaName != null) {
          _addBytesFile(request, mediaBytes, mediaName);
        }
      } else if (mediaFile != null) {
        await _addPathFile(request, mediaFile);
      }

      debugPrint("🚀 DISPATCHING SERVICE: POST $uri");
      debugPrint("📦 PAYLOAD SENT: ${request.fields}");
      debugPrint("🌐 Lang header: $lang");

      // 60s timeout accommodates large file streams and Render free-tier environment cold starts
      final streamed =
          await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("🎉 Service Submission Successful");
        return true;
      } else {
        debugPrint("❌ Server Error ${response.statusCode}: ${response.body}");
        return false;
      }
    } on SocketException {
      debugPrint(
          "❌ Connection Error: Service server is completely unreachable");
      return false;
    } catch (e) {
      debugPrint("❌ UserServiceService Exception: $e");
      return false;
    }
  }

  // ── Private media helpers ──────────────────────────────────────────────────
  static void _addBytesFile(
      http.MultipartRequest request, Uint8List bytes, String fileName) {
    final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
    final parts = mimeType.split('/');
    request.fields['mediaType'] = parts.first == 'video' ? 'video' : 'photo';
    request.files.add(http.MultipartFile.fromBytes(
      'media',
      bytes,
      filename: fileName,
      contentType: MediaType(parts[0], parts[1]),
    ));
  }

  static Future<void> _addPathFile(
      http.MultipartRequest request, File file) async {
    final fileName = path.basename(file.path);
    final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
    final parts = mimeType.split('/');
    request.fields['mediaType'] = parts.first == 'video' ? 'video' : 'photo';
    request.files.add(await http.MultipartFile.fromPath(
      'media',
      file.path,
      contentType: MediaType(parts[0], parts[1]),
    ));
  }
}

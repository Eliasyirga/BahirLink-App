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
  static String get baseUrl {
    if (kIsWeb) return "http://localhost:5000/api";
    if (Platform.isAndroid) return "http://10.0.2.2:5000/api";
    return "http://localhost:5000/api";
  }

  /// Retrieves the logged-in user's ID from local storage
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final rawId = prefs.get("userId");
    if (rawId is int) return rawId;
    if (rawId is String) return int.tryParse(rawId);
    return null;
  }

  /// Sends a service request to the backend with optional media
  static Future<bool> sendUserService({
    required int userId,
    required ServiceReportModel report,
    Uint8List? mediaBytes,
    File? mediaFile,
    String? mediaName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("accessToken");

      if (token == null) {
        debugPrint("❌ No access token found");
        return false;
      }

      // ✅ Endpoint matches Backend: POST /api/service/create/:userId
      final uri = Uri.parse("$baseUrl/service/create/$userId");
      final request = http.MultipartRequest("POST", uri);
      request.headers['Authorization'] = "Bearer $token";

      // ✅ Fix: Mandatory Model Field 'name'
      request.fields['name'] =
          "Service Req: ${report.subdivision ?? 'General'}";

      // Map model fields to multipart text fields
      final data = report.toJson();
      data.forEach((key, value) {
        if (value != null) {
          // ✅ FIX: Option A - Format ISO Date string to PostgreSQL TIME format (HH:mm:ss)
          if (key == 'time' && value is String && value.contains('T')) {
            try {
              // Extract "05:40:00" from "2026-04-16T05:40:00.000"
              final timeOnly = value.split('T')[1].split('.')[0];
              request.fields[key] = timeOnly;
            } catch (e) {
              request.fields[key] = value.toString();
            }
          } else {
            request.fields[key] = value.toString();
          }
        }
      });

      // 📎 Media Logic
      if (kIsWeb) {
        if (mediaBytes != null && mediaName != null) {
          final mimeType =
              lookupMimeType(mediaName) ?? "application/octet-stream";
          final split = mimeType.split("/");
          request.fields['mediaType'] = split.first == 'video'
              ? 'video'
              : 'photo';

          request.files.add(
            http.MultipartFile.fromBytes(
              "media",
              mediaBytes,
              filename: mediaName,
              contentType: MediaType(split[0], split[1]),
            ),
          );
        }
      } else if (mediaFile != null) {
        final filename = path.basename(mediaFile.path);
        final mimeType = lookupMimeType(filename) ?? "application/octet-stream";
        final split = mimeType.split("/");
        request.fields['mediaType'] = split.first == 'video'
            ? 'video'
            : 'photo';

        request.files.add(
          await http.MultipartFile.fromPath(
            "media",
            mediaFile.path,
            contentType: MediaType(split[0], split[1]),
          ),
        );
      }

      debugPrint("🚀 Requesting: POST $uri");
      debugPrint("📦 Payload: ${request.fields}");

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("🎉 Service request successful");
        return true;
      } else {
        debugPrint("❌ Server Error ${response.statusCode}: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ UserServiceService Exception: $e");
      return false;
    }
  }
}

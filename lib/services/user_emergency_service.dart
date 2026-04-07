import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/emergency_report_model.dart';

/// ==========================================================
/// 🌟 UserEmergencyService (FIXED & CLEAN)
/// 📍 Location matches Guest (lat/lng direct)
/// ==========================================================
class UserEmergencyService {
  // ========================================================
  // 🌐 Base URL depending on platform
  // ========================================================
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:5000/api";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:5000/api";
    } else {
      return "http://localhost:5000/api";
    }
  }

  // ========================================================
  // 👤 Get userId from SharedPreferences
  // ========================================================
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final rawId = prefs.get("userId");

    if (rawId is int) return rawId;
    if (rawId is String) return int.tryParse(rawId);

    return null;
  }

  // ========================================================
  // 🚨 Send Emergency Report
  // ========================================================
  static Future<bool> sendUserEmergency({
    required int userId,
    required EmergencyReportModel report,

    // 📍 Location
    double? latitude,
    double? longitude,

    // 📎 Media
    Uint8List? mediaBytes,
    File? mediaFile,
    String? mediaName,
  }) async {
    try {
      // -------------------------------
      // 🔑 Get access token
      // -------------------------------
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("accessToken");

      if (token == null || token.isEmpty) {
        print("❌ No access token found");
        return false;
      }

      // -------------------------------
      // 🔗 API endpoint
      // -------------------------------
      final uri = Uri.parse("$baseUrl/emergencies/users/$userId");

      final request = http.MultipartRequest("POST", uri);
      request.headers['Authorization'] = "Bearer $token";

      // -------------------------------
      // 📝 Add report fields
      // -------------------------------
      final data = report.toJsonForUser();

      data.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // -------------------------------
      // 📍 Add Location
      // -------------------------------
      if (latitude != null) {
        request.fields["latitude"] = latitude.toString();
      }

      if (longitude != null) {
        request.fields["longitude"] = longitude.toString();
      }

      // -------------------------------
      // 📎 Attach Media
      // -------------------------------
      if (kIsWeb) {
        // 🌐 Web Media
        if (mediaBytes != null && mediaName != null) {
          final mimeType =
              lookupMimeType(mediaName) ?? "application/octet-stream";

          final split = mimeType.split("/");

          final contentType = MediaType(split[0], split[1]);

          request.fields['mediaType'] = split.first == 'video'
              ? 'video'
              : 'photo';

          request.files.add(
            http.MultipartFile.fromBytes(
              "media",
              mediaBytes, // ✅ Safe now (checked above)
              filename: mediaName,
              contentType: contentType,
            ),
          );

          print("📎 Web media attached: $mediaName");
        }
      } else {
        // 📱 Mobile/Desktop Media
        if (mediaFile != null) {
          final filename = path.basename(mediaFile.path);

          final mimeType =
              lookupMimeType(filename) ?? "application/octet-stream";

          final split = mimeType.split("/");

          final contentType = MediaType(split[0], split[1]);

          request.fields['mediaType'] = split.first == 'video'
              ? 'video'
              : 'photo';

          request.files.add(
            await http.MultipartFile.fromPath(
              "media",
              mediaFile.path,
              contentType: contentType,
            ),
          );

          print("📎 File attached: $filename");
        }
      }

      // -------------------------------
      // 🚀 Send request
      // -------------------------------
      print("🔵 Sending emergency report...");
      print("🌐 URL: $uri");
      print("📍 Latitude: $latitude");
      print("📍 Longitude: $longitude");

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("✅ STATUS: ${response.statusCode}");
      print("📦 BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("🎉 Emergency sent successfully");
        return true;
      } else {
        print("❌ Failed to send emergency");
        return false;
      }
    } catch (e) {
      print("❌ UserEmergencyService Error: $e");
      return false;
    }
  }
}

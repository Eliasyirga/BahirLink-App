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
/// 🌟 UserEmergencyService
/// 🔥 Works on Web + Android Emulator + iOS + others
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
  // ✅ Get userId directly from local storage (no API call)
  // ========================================================
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt("userId");
    print("LOCAL USER ID: $id");
    return id;
  }

  // ========================================================
  // 🚨 Send Emergency Report
  // ========================================================
  static Future<bool> sendUserEmergency({
    required int userId,
    required EmergencyReportModel report,
    Uint8List? mediaBytes,
    File? mediaFile,
    String? mediaName,
  }) async {
    try {
      // -------------------------------
      // 🔑 Retrieve access token
      // -------------------------------
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("accessToken");

      if (token == null || token.isEmpty) {
        print("❌ No token found");
        return false;
      }

      // -------------------------------
      // 🔗 Use backend endpoint: /api/emergencies/users/:userId
      // -------------------------------
      final uri = Uri.parse("$baseUrl/emergencies/users/$userId");
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = "Bearer $token";

      // -------------------------------
      // 📝 Add report fields
      // -------------------------------
      final data = report.toJsonForUser();
      data.forEach((key, value) {
        if (value != null) request.fields[key] = value.toString();
      });

      // -------------------------------
      // 📎 Attach media if exists
      // -------------------------------
      if ((kIsWeb && mediaBytes != null && mediaName != null) ||
          (!kIsWeb && mediaFile != null)) {
        String filename;
        MediaType contentType;

        if (kIsWeb) {
          filename = mediaName!; // ✅ Fixed nullable issue
          final mimeType =
              lookupMimeType(filename) ?? 'application/octet-stream';
          final split = mimeType.split('/');
          contentType = MediaType(split[0], split[1]);
          request.fields['mediaType'] = split.first == 'video'
              ? 'video'
              : 'photo';

          request.files.add(
            http.MultipartFile.fromBytes(
              'media',
              mediaBytes!,
              filename: filename,
              contentType: contentType,
            ),
          );
        } else {
          filename = path.basename(mediaFile!.path);
          final mimeType =
              lookupMimeType(filename) ?? 'application/octet-stream';
          final split = mimeType.split('/');
          contentType = MediaType(split[0], split[1]);
          request.fields['mediaType'] = split.first == 'video'
              ? 'video'
              : 'photo';

          request.files.add(
            await http.MultipartFile.fromPath(
              'media',
              mediaFile.path,
              contentType: contentType,
            ),
          );
        }
      }

      // -------------------------------
      // 🔵 Send request & log response
      // -------------------------------
      print("🔵 Sending request to: $uri");
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("❌ UserEmergencyService Error: $e");
      return false;
    }
  }
}

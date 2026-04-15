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
  static String get baseUrl {
    if (kIsWeb) return "http://localhost:5000/api";
    if (Platform.isAndroid) return "http://10.0.2.2:5000/api";
    return "http://localhost:5000/api";
  }

  // ✅ FIX: Added back the missing getUserId method
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final rawId = prefs.get("userId");
    if (rawId is int) return rawId;
    if (rawId is String) return int.tryParse(rawId);
    return null;
  }

  static Future<bool> sendUserEmergency({
    required int userId,
    required EmergencyReportModel report,
    double? latitude,
    double? longitude,
    Uint8List? mediaBytes,
    File? mediaFile,
    String? mediaName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("accessToken");

      if (token == null) {
        print("❌ No access token found");
        return false;
      }

      final uri = Uri.parse("$baseUrl/emergencies/users/$userId");
      final request = http.MultipartRequest("POST", uri);
      request.headers['Authorization'] = "Bearer $token";

      // 📝 Get the base map from the model
      final data = report.toJsonForUser();

      // ✅ FIX: Use 'report.kebele' instead of 'report.kebeleId'
      // Mapping 'kebele' from model to 'kebeleId' for the Backend
      request.fields['kebeleId'] = report.kebele?.toString() ?? "";
      request.fields['subdivision'] = report.subdivision ?? "";

      // Add remaining fields
      data.forEach((key, value) {
        if (value != null && key != 'kebele' && key != 'subdivision') {
          request.fields[key] = value.toString();
        }
      });

      if (latitude != null) request.fields["latitude"] = latitude.toString();
      if (longitude != null) request.fields["longitude"] = longitude.toString();

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

      print("🚀 Requesting: POST $uri");
      print("📦 Payload sent to backend: ${request.fields}");

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("🎉 Emergency report successful");
        return true;
      } else {
        print("❌ Server Error ${response.statusCode}: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ UserEmergencyService Exception: $e");
      return false;
    }
  }
}

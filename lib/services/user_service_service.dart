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

  /// Sends a service request to the backend with the standardized "media" key
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
        debugPrint("❌ UserService Error: Access token missing");
        return false;
      }

      // ✅ Endpoint matches Backend: POST /api/service/create/:userId
      final uri = Uri.parse("$baseUrl/service/create/$userId");
      final request = http.MultipartRequest("POST", uri);
      request.headers['Authorization'] = "Bearer $token";

      // 📝 1. Map Model Data to Backend Fields
      // 'name' is required by backend, using 'subdivision' as the source
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

      // Format Time (ISO -> HH:mm:ss) to prevent DB timestamp errors
      request.fields['time'] = report.time
          .toIso8601String()
          .split('T')[1]
          .split('.')[0];

      // 📎 2. Synchronized Media Logic
      // IMPORTANT: This key MUST be "media" to match upload.single("media")
      const String fileKey = "media";

      if (kIsWeb) {
        if (mediaBytes != null && mediaName != null) {
          final mimeType = lookupMimeType(mediaName) ?? "image/jpeg";
          final split = mimeType.split("/");

          request.fields['mediaType'] = split.first == 'video'
              ? 'video'
              : 'photo';

          request.files.add(
            http.MultipartFile.fromBytes(
              fileKey,
              mediaBytes,
              filename: mediaName,
              contentType: MediaType(split[0], split[1]),
            ),
          );
        }
      } else if (mediaFile != null) {
        final filename = path.basename(mediaFile.path);
        final mimeType = lookupMimeType(filename) ?? "image/jpeg";
        final split = mimeType.split("/");

        request.fields['mediaType'] = split.first == 'video'
            ? 'video'
            : 'photo';

        request.files.add(
          await http.MultipartFile.fromPath(
            fileKey,
            mediaFile.path,
            contentType: MediaType(split[0], split[1]),
          ),
        );
      }

      debugPrint("🚀 DISPATCHING SERVICE: POST $uri");
      debugPrint("📦 PAYLOAD SENT: ${request.fields}");

      // 🚀 3. Execute Request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 25),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("🎉 Service Submission Successful");
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

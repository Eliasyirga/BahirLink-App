import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class VerificationService {
  // 🔥 SET TO 'true' to develop locally. SET TO 'false' to use live Render server.
  static const bool useLocalBackup = false;

  // ─── Base URL Getter ───────────────────────────────────────────────────────
  static String get serverUrl {
    if (!useLocalBackup) {
      return "https://bahirlink-backend-1.onrender.com";
    }
    if (kIsWeb) return "http://localhost:5000";
    if (Platform.isAndroid)
      return "http://10.0.2.2:5000"; // Android Emulator address
    return "http://localhost:5000"; // iOS Simulator or Desktop
  }

  // Derived api routing target
  String get baseUrl => "$serverUrl/api/verify";

  // ─── Verify Identity ───────────────────────────────────────────────────────
  /// Upload ID image + selfie for verification processing
  Future<Map<String, dynamic>> verify({
    required File idImage,
    required File selfie,
    String lang = 'en',
  }) async {
    try {
      final uri = Uri.parse(baseUrl);
      final request = http.MultipartRequest('POST', uri);

      // Inject default localization or standard request parameters if required by core filters
      request.headers.addAll({
        'Accept': 'application/json',
        'Accept-Language': lang,
      });

      // Attach National ID Documents or alternative clearance graphics
      request.files.add(
        await http.MultipartFile.fromPath(
          'id_image',
          idImage.path,
          filename: path.basename(idImage.path),
        ),
      );

      // Attach Live Capture Portrait Match Payload
      request.files.add(
        await http.MultipartFile.fromPath(
          'selfie',
          selfie.path,
          filename: path.basename(selfie.path),
        ),
      );

      debugPrint("🚀 DISPATCHING VERIFICATION DATA: POST $uri");

      // 60-second limit buffers dual image streams against container wake-up cycles safely
      final streamed =
          await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        debugPrint(
            "❌ Verification Processing Failure: Status ${response.statusCode}");
        return {
          'success': false,
          'error': 'Server error ${response.statusCode}',
          'body': response.body,
        };
      }
    } on SocketException {
      debugPrint(
          "❌ Connection Error: Identity service server is completely unreachable");
      return {
        'success': false,
        'error': 'Network connection failed. Server unreachable.',
      };
    } catch (e) {
      debugPrint("❌ VerificationService Exception: $e");
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}

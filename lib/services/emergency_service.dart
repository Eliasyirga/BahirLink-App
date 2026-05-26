import 'dart:convert';
import 'dart:io' show File, Platform, SocketException;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'; // for Localizations
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

class EmergencyService {
  // 🔥 SET TO 'true' to develop locally. SET TO 'false' to use live Render server.
  static const bool useLocalBackup = false;

  // 🌍 Dynamic Origin URL Router
  static String get baseUrl {
    if (!useLocalBackup) {
      return "https://bahirlink-backend-1.onrender.com/api";
    }
    if (kIsWeb) {
      return "http://localhost:5000/api";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:5000/api"; // Android Emulator address
    } else {
      return "http://localhost:5000/api"; // iOS Simulator or Desktop
    }
  }

  static String get _guestEndpoint => "$baseUrl/emergencies/guests";
  static String get _userEndpoint => "$baseUrl/emergencies/user";

  // ─── Shared headers ────────────────────────────────────────────────────────
  static Map<String, String> _headers(String lang) => {
        'Accept': 'application/json',
        'Accept-Language':
            lang, // Handles Amharic / English auto-translation mappings
      };

  // ─── Locale helper ─────────────────────────────────────────────────────────
  static String resolvelang([BuildContext? context]) {
    if (context == null) return 'en';
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'am' ? 'am' : 'en';
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CREATE GUEST EMERGENCY
  // ══════════════════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> createGuestEmergency({
    required String contactNo,
    required String kebele,
    required String subdivision,
    String? street,
    String? description,
    required String emergencyTypeId,
    required String categoryId,
    double? latitude,
    double? longitude,
    String? time,
    String? deviceId,
    Uint8List? mediaBytes,
    File? mediaFile,
    String? mediaName,
    String lang = 'en',
  }) async {
    try {
      final uri = Uri.parse(_guestEndpoint);
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_headers(lang));

      request.fields.addAll({
        "contactNo": contactNo,
        "kebele": kebele,
        "subdivision": subdivision,
        "emergencyTypeId": emergencyTypeId,
        "categoryId": categoryId,
        "time": time ?? DateTime.now().toIso8601String(),
        if (street != null) "street": street,
        if (description != null) "description": description,
        if (latitude != null) "latitude": latitude.toString(),
        if (longitude != null) "longitude": longitude.toString(),
        if (deviceId != null) "deviceId": deviceId,
      });

      await _attachMedia(request, mediaBytes, mediaFile, mediaName);

      return await _send(request);
    } on SocketException {
      return {
        "success": false,
        "message": "Server unreachable. Check connection."
      };
    } catch (e) {
      debugPrint("createGuestEmergency error: $e");
      return {"success": false, "message": "Connection Error"};
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CREATE USER EMERGENCY
  // ══════════════════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> createUserEmergency({
    required String authToken,
    required String kebeleId,
    required String subdivision,
    required String emergencyTypeId,
    String? categoryId,
    String? street,
    String? description,
    double? latitude,
    double? longitude,
    String? time,
    Uint8List? mediaBytes,
    File? mediaFile,
    String? mediaName,
    String lang = 'en',
  }) async {
    try {
      final uri = Uri.parse(_userEndpoint);
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        ..._headers(lang),
        'Authorization': 'Bearer $authToken',
      });

      request.fields.addAll({
        "kebeleId": kebeleId,
        "subdivision": subdivision,
        "emergencyTypeId": emergencyTypeId,
        if (categoryId != null) "categoryId": categoryId,
        if (street != null) "street": street,
        if (description != null) "description": description,
        if (latitude != null) "latitude": latitude.toString(),
        if (longitude != null) "longitude": longitude.toString(),
        if (time != null) "time": time,
      });

      await _attachMedia(request, mediaBytes, mediaFile, mediaName);

      return await _send(request);
    } on SocketException {
      return {
        "success": false,
        "message": "Server unreachable. Check connection."
      };
    } catch (e) {
      debugPrint("createUserEmergency error: $e");
      return {"success": false, "message": "Connection Error"};
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GET EMERGENCIES (user or guest)
  // ══════════════════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> getEmergencies({
    required String userOrGuestId,
    bool isGuest = false,
    String lang = 'en',
  }) async {
    try {
      final uri = Uri.parse("$baseUrl/emergencies/$userOrGuestId")
          .replace(queryParameters: {'isGuest': isGuest.toString()});

      final response = await http
          .get(uri, headers: _headers(lang))
          .timeout(const Duration(seconds: 30));
      return _parseResponse(response);
    } catch (e) {
      debugPrint("getEmergencies error: $e");
      return {"success": false, "message": "Connection Error"};
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GET SINGLE EMERGENCY BY ID
  // ══════════════════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> getEmergencyById({
    required String id,
    String lang = 'en',
  }) async {
    try {
      final uri = Uri.parse("$baseUrl/emergencies/$id");
      final response = await http
          .get(uri, headers: _headers(lang))
          .timeout(const Duration(seconds: 30));
      return _parseResponse(response);
    } catch (e) {
      debugPrint("getEmergencyById error: $e");
      return {"success": false, "message": "Connection Error"};
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GET EMERGENCIES BY DEVICE ID
  // ══════════════════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> getEmergenciesByDeviceId({
    required String deviceId,
    String lang = 'en',
  }) async {
    try {
      final uri = Uri.parse("$baseUrl/emergencies/device/$deviceId");
      final response = await http
          .get(uri, headers: _headers(lang))
          .timeout(const Duration(seconds: 30));
      return _parseResponse(response);
    } catch (e) {
      debugPrint("getEmergenciesByDeviceId error: $e");
      return {"success": false, "message": "Connection Error"};
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // UPDATE EMERGENCY STATUS
  // ══════════════════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> updateEmergencyStatus({
    required String authToken,
    required String emergencyId,
    required String status,
    String? report,
    String lang = 'en',
  }) async {
    try {
      final uri = Uri.parse("$baseUrl/emergencies/$emergencyId/status");
      final response = await http
          .patch(
            uri,
            headers: {
              ..._headers(lang),
              'Authorization': 'Bearer $authToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              "status": status,
              if (report != null) "report": report,
            }),
          )
          .timeout(const Duration(seconds: 30));
      return _parseResponse(response);
    } catch (e) {
      debugPrint("updateEmergencyStatus error: $e");
      return {"success": false, "message": "Connection Error"};
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DELETE EMERGENCY
  // ══════════════════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> deleteEmergency({
    required String authToken,
    required String emergencyId,
    bool isGuest = false,
    String? guestId,
    String lang = 'en',
  }) async {
    try {
      final uri = Uri.parse("$baseUrl/emergencies/$emergencyId").replace(
        queryParameters: {
          'isGuest': isGuest.toString(),
          if (guestId != null) 'guestId': guestId,
        },
      );
      final response = await http.delete(uri, headers: {
        ..._headers(lang),
        'Authorization': 'Bearer $authToken',
      }).timeout(const Duration(seconds: 30));
      return _parseResponse(response);
    } catch (e) {
      debugPrint("deleteEmergency error: $e");
      return {"success": false, "message": "Connection Error"};
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  static Future<void> _attachMedia(
    http.MultipartRequest request,
    Uint8List? mediaBytes,
    File? mediaFile,
    String? mediaName,
  ) async {
    if (kIsWeb) {
      if (mediaBytes != null && mediaName != null) {
        _addBytesFile(request, mediaBytes, mediaName);
      }
    } else {
      if (mediaFile != null) {
        await _addPathFile(request, mediaFile);
      }
    }
  }

  static void _addBytesFile(
      http.MultipartRequest request, Uint8List bytes, String fileName) {
    final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
    final parts = mimeType.split('/');
    request.fields['mediaType'] = parts.first == "video" ? "video" : "photo";
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
    request.fields['mediaType'] = parts.first == "video" ? "video" : "photo";
    request.files.add(await http.MultipartFile.fromPath(
      'media',
      file.path,
      contentType: MediaType(parts[0], parts[1]),
    ));
  }

  static Future<Map<String, dynamic>> _send(
      http.MultipartRequest request) async {
    // 60 seconds allocated to allow free-tier spin-up alongside media stream processing
    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    return _parseResponse(response);
  }

  static Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          "success": decoded['success'] ?? true,
          "data": decoded['data'] ?? decoded,
        };
      }
      return {
        "success": false,
        "message": decoded['message'] ?? "Server error ${response.statusCode}",
      };
    } catch (_) {
      return {
        "success": false,
        "message": "Unexpected response (${response.statusCode})",
      };
    }
  }
}

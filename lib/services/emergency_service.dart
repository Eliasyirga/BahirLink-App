import 'dart:typed_data';
import 'dart:io' show File, Platform;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'; // for Localizations
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

class EmergencyService {
  // ─── Base URL ──────────────────────────────────────────────────────────────
  static String get baseUrl {
    if (kIsWeb) return "http://localhost:5000/api";
    if (Platform.isAndroid) return "http://10.0.2.2:5000/api";
    return "http://localhost:5000/api";
  }

  static String get _guestEndpoint => "$baseUrl/emergencies/guests";
  static String get _userEndpoint => "$baseUrl/emergencies/user";

  // ─── Shared headers ────────────────────────────────────────────────────────
  /// Pass Accept-Language so the backend's getLang() returns the correct locale
  /// and autoTranslate / localize work properly.
  ///
  /// The backend's autoTranslate() will detect the language of the submitted
  /// text (Amharic or English) and always persist BOTH { en, am } in the DB.
  static Map<String, String> _headers(String lang) => {
        'Accept': 'application/json',
        'Accept-Language': lang,
      };

  // ─── Locale helper ─────────────────────────────────────────────────────────
  /// Resolves the current app locale to a BCP-47 language tag ('en' or 'am').
  /// Falls back to 'en' when no BuildContext is available (e.g. background calls).
  static String resolvelang([BuildContext? context]) {
    if (context == null) return 'en';
    final locale = Localizations.localeOf(context);
    // Amharic locale code is 'am'; everything else defaults to English.
    return locale.languageCode == 'am' ? 'am' : 'en';
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CREATE GUEST EMERGENCY
  //
  // Pass [lang] as the current app locale ('en' or 'am').
  // The backend will detect the actual language of [subdivision] / [description]
  // and store both English and Amharic versions regardless of which was typed.
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

      // Plain string fields are sent as-is.
      // The backend's autoTranslate() detects whether the text is Amharic or
      // English, then saves { en: "...", am: "..." } to the JSONB column.
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
    } catch (e) {
      debugPrint("createGuestEmergency error: $e");
      return {"success": false, "message": "Connection Error"};
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CREATE USER EMERGENCY
  //
  // Pass [lang] as the current app locale ('en' or 'am').
  // Same bidirectional translation logic applies on the backend.
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

      final response = await http.get(uri, headers: _headers(lang));
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
      final response = await http.get(uri, headers: _headers(lang));
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
      final response = await http.get(uri, headers: _headers(lang));
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
      final response = await http.patch(
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
      );
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
      });
      return _parseResponse(response);
    } catch (e) {
      debugPrint("deleteEmergency error: $e");
      return {"success": false, "message": "Connection Error"};
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  /// Attach a media file to a multipart request (web bytes or mobile File).
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

  /// Send a MultipartRequest and normalise the response into
  /// { success, data/message }.
  static Future<Map<String, dynamic>> _send(
      http.MultipartRequest request) async {
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
    return _parseResponse(response);
  }

  /// Parse an http.Response into a consistent { success, data/message } map.
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
        "message":
            decoded['message'] ?? "Server error ${response.statusCode}",
      };
    } catch (_) {
      return {
        "success": false,
        "message": "Unexpected response (${response.statusCode})",
      };
    }
  }
}
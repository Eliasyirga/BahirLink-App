import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../config/api_config.dart';
import 'token_store.dart';

class VerificationService {
  // ─── Base URL Getter ───────────────────────────────────────────────────────
  static String get serverUrl => ApiConfig.baseUrl;

  // Derived api routing target
  String get baseUrl => "$serverUrl/api/verify";

  // ─── Verify Identity ───────────────────────────────────────────────────────
  /// Upload ID image + selfie for verification processing.
  ///
  /// `POST /api/verify` requires `Authorization: Bearer <accessToken>`. When
  /// [token] is not supplied the persisted `accessToken` is used.
  ///
  /// Always returns a map with `success` and, on failure, a user-facing
  /// `error` string (plus `statusCode` / `sessionExpired` where relevant).
  Future<Map<String, dynamic>> verify({
    required File idImage,
    required File selfie,
    String lang = 'en',
    String? token,
  }) async {
    try {
      var accessToken = (token ?? '').trim();
      if (accessToken.isEmpty) {
        accessToken = await TokenStore.readAccessToken() ?? '';
      }
      accessToken = accessToken.replaceFirst(RegExp(r'^Bearer\s+'), '');
      if (accessToken.isEmpty) {
        return {
          'success': false,
          'sessionExpired': true,
          'error': const SessionExpiredException().toString(),
        };
      }

      final uri = Uri.parse(baseUrl);
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Accept': 'application/json',
        'Accept-Language': lang,
        'Authorization': 'Bearer $accessToken',
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

      Map<String, dynamic>? body;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) body = Map<String, dynamic>.from(decoded);
      } catch (_) {}

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = body ?? {'success': true};
        final data = result['data'];
        if (data is Map && data['decision'] == 'rejected') {
          return {
            ...result,
            'success': false,
            'error': "Your selfie didn't match the photo on your ID. "
                'Please retake both photos in good lighting and try again.',
          };
        }
        return result;
      }

      debugPrint(
          "❌ Verification Processing Failure: Status ${response.statusCode}");

      final serverMessage = (body?['message'] ?? body?['error'])?.toString();
      final String error;
      switch (response.statusCode) {
        case 401:
          return {
            'success': false,
            'statusCode': 401,
            'sessionExpired': true,
            'error': const SessionExpiredException().toString(),
          };
        case 503:
          error = 'Identity verification is temporarily unavailable. '
              'Please try again later.';
          break;
        case 400:
        case 422:
          error = serverMessage ??
              'We could not read your photos. Please retake them and try again.';
          break;
        case 413:
          error = 'The photos are too large. Please retake them and try again.';
          break;
        default:
          error = 'Verification failed due to a server error '
              '(${response.statusCode}). Please try again later.';
      }
      return {
        'success': false,
        'statusCode': response.statusCode,
        'error': error,
      };
    } on SocketException {
      debugPrint(
          "❌ Connection Error: Identity service server is completely unreachable");
      return {
        'success': false,
        'error': 'Could not reach the server. Check your internet connection '
            'and try again.',
      };
    } on TimeoutException {
      return {
        'success': false,
        'error': 'The server took too long to respond. Please try again.',
      };
    } catch (e) {
      debugPrint("❌ VerificationService Exception: $e");
      return {
        'success': false,
        'error': 'Something went wrong during verification. Please try again.',
      };
    }
  }
}

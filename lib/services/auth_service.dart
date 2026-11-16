import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'call_services.dart';
import 'token_store.dart';

class AuthService {
  // 🌍 Automatically switches between Live Render Server and Local Backups
  static String get baseUrl => ApiConfig.baseUrl;

  // -------------------- REGISTER --------------------
  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/api/users/register");

      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "firstName": firstName.trim(),
              "lastName": lastName.trim(),
              "email": email.trim().toLowerCase(),
              "password": password,
            }),
          )
          .timeout(const Duration(
              seconds: 60)); // Added timeout for free tier spin-up

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }

  // -------------------- VERIFY EMAIL CODE --------------------
  static Future<Map<String, dynamic>> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/api/users/verify-email-code");

      final intCode = int.tryParse(code);
      if (intCode == null) {
        return {"success": false, "error": "Invalid code format"};
      }

      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": email.trim().toLowerCase(),
              "code": intCode,
            }),
          )
          .timeout(const Duration(seconds: 60));

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }

  // -------------------- LOGIN --------------------
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/api/users/login");

      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": email.trim().toLowerCase(),
              "password": password,
              "rememberMe": rememberMe,
            }),
          )
          .timeout(const Duration(seconds: 60));

      final data = jsonDecode(response.body);

      // ✅ Save tokens if login successful. This includes temporary-password
      // logins (mustChangePassword == true): the token is needed to call
      // change-password right after signing in.
      if (data['success'] == true && data['accessToken'] != null) {
        await TokenStore.saveTokens(
          accessToken: data['accessToken'].toString(),
          refreshToken: data['refreshToken']?.toString(),
        );

        final prefs = await SharedPreferences.getInstance();

        // 🔥 Save userId if backend sends it
        if (data['user'] != null && data['user']['id'] != null) {
          await prefs.setInt("userId", data['user']['id']);
        } else if (data['id'] != null) {
          await prefs.setInt("userId", data['id']);
        }
      }

      return data;
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }

  // -------------------- GET PROFILE --------------------
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await TokenStore.readAccessToken() ?? "";

      if (token.isEmpty) {
        return {"success": false, "error": "No access token found"};
      }

      final url = Uri.parse("$baseUrl/api/users/profile");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 30));

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }

  // -------------------- LOGOUT --------------------
  /// Per-user (non-secret) SharedPreferences keys. Tokens live in
  /// [TokenStore]. Device-level settings (language, translation toggle, app
  /// config) are intentionally kept.
  static const List<String> _sessionKeys = [
    "userId",
  ];

  /// The single logout path: clears every per-user credential and tears down
  /// the global call socket so the next user gets a fresh connection.
  /// (Chat sockets are owned by ChatPage and closed when that page disposes.)
  static Future<void> logout() async {
    CallService.I.disconnect();

    await TokenStore.clear();

    final prefs = await SharedPreferences.getInstance();
    for (final key in _sessionKeys) {
      await prefs.remove(key);
    }
  }

  // -------------------- FORGOT PASSWORD --------------------
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/api/users/forgot-password");

      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email.trim().toLowerCase()}),
          )
          .timeout(const Duration(seconds: 60));

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }

  // -------------------- CHANGE PASSWORD --------------------
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await TokenStore.readAccessToken() ?? "";

      if (token.isEmpty) {
        return {"success": false, "error": "No access token found"};
      }

      final url = Uri.parse("$baseUrl/api/users/change-password");

      final response = await http
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode({
              "currentPassword": currentPassword,
              "newPassword": newPassword,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }
}

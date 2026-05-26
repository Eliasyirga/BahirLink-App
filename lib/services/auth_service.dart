import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // 🔥 SET TO 'true' to develop locally. SET TO 'false' to use live Render server.
  static const bool useLocalBackup = false;

  // 🌍 Automatically switches between Live Render Server and Local Backups
  static String get baseUrl {
    if (!useLocalBackup) {
      // Your live production backend on Render
      return "https://bahirlink-backend-1.onrender.com";
    }

    // 🔄 Local backups if Render is down or if you're developing locally
    if (kIsWeb) {
      return "http://localhost:5000";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:5000"; // Android Emulator local address
    } else {
      return "http://localhost:5000"; // iOS Simulator or Desktop
    }
  }

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

      // ✅ Save tokens if login successful and not temporary password
      if (data['success'] == true &&
          data['accessToken'] != null &&
          data['mustChangePassword'] != true) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString("accessToken", data['accessToken']);

        if (data['refreshToken'] != null) {
          await prefs.setString("refreshToken", data['refreshToken']);
        }

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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("accessToken") ?? "";

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
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove("accessToken");
    await prefs.remove("refreshToken");
    await prefs.remove("userId");
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("accessToken") ?? "";

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

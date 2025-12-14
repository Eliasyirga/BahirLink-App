import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = "http://localhost:5000";

  // -------------------- REGISTER --------------------
  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/api/users/register");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "firstName": firstName,
          "lastName": lastName,
          "email": email,
          "password": password,
        }),
      );

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
      if (intCode == null)
        return {"success": false, "error": "Invalid code format"};

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email.trim().toLowerCase(),
          "code": intCode,
        }),
      );

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
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "rememberMe": rememberMe,
        }),
      );

      final data = jsonDecode(response.body);

      // Save tokens if login successful and not temporary password
      if (data['success'] == true &&
          data['accessToken'] != null &&
          data['mustChangePassword'] != true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("accessToken", data['accessToken']);
        if (data['refreshToken'] != null) {
          await prefs.setString("refreshToken", data['refreshToken']);
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

      if (token.isEmpty)
        return {"success": false, "error": "No access token found"};

      final url = Uri.parse("$baseUrl/api/users/profile");
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

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
  }

  // -------------------- FORGOT PASSWORD (Temporary Password) --------------------
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/api/users/forgot-password");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

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

      if (token.isEmpty)
        return {"success": false, "error": "No access token found"};

      final url = Uri.parse("$baseUrl/api/users/change-password");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "currentPassword": currentPassword,
          "newPassword": newPassword,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "error": "Network error: $e"};
    }
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';
import 'token_store.dart';

class UserService {
  // ─── Base URL Getter ───────────────────────────────────────────────────────
  static String get baseUrl => ApiConfig.baseUrl;

  // ─── Get User Profile ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final token = await TokenStore.readAccessToken();

      if (token == null || token.isEmpty) {
        debugPrint("❌ No access token stored");
        return null;
      }

      final response = await http.get(
        Uri.parse("$baseUrl/api/users/profile"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(
          seconds: 60)); // 60s timeout handles live server wakeup delays

      debugPrint("GET STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _normalizeUserData(data['user'] ?? data);
      }

      return null;
    } on SocketException {
      debugPrint("❌ Connection Error: User profile server is unreachable");
      return null;
    } catch (e) {
      debugPrint("GET ERROR: $e");
      return null;
    }
  }

  // ─── Update User Profile ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> updateProfile(
    Map<String, dynamic> updates,
  ) async {
    try {
      final token = await TokenStore.readAccessToken();

      if (token == null || token.isEmpty) {
        debugPrint("❌ No access token stored");
        return null;
      }

      final response = await http
          .put(
            Uri.parse("$baseUrl/api/users/profile"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode(updates),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _normalizeUserData(data['user'] ?? data);
      }

      return null;
    } on SocketException {
      debugPrint("❌ Connection Error: Update profile server is unreachable");
      return null;
    } catch (e) {
      debugPrint("UPDATE ERROR: $e");
      return null;
    }
  }

  // ─── Logout ────────────────────────────────────────────────────────────────
  /// Delegates to [AuthService.logout] so there is exactly one logout path.
  static Future<void> logout() async {
    await AuthService.logout();
    debugPrint("🔒 Session cleared. Logout processed successfully.");
  }

  // ─── Data Normalization ─────────────────────────────────────────────────────
  static Map<String, dynamic> _normalizeUserData(Map<String, dynamic> user) {
    final firstName = user['firstName'] ?? '';
    final lastName = user['lastName'] ?? '';

    return {
      'firstName': firstName,
      'lastName': lastName,
      'name':
          (firstName + " " + lastName).trim(), // Aggregated display fallback
      'email': user['email'] ?? '',
      'phone': user['phone'] ?? '',
      'country': user['country'] ?? '',
      'city': user['city'] ?? '',
      'address': user['address'] ?? '',
      'dateOfBirth': user['dateOfBirth'] ?? '',
      'gender': user['gender'] ?? '',
      'role': user['role'] ?? 'User',
      'createdAt': user['createdAt'] ?? DateTime.now().toIso8601String(),
    };
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  // 🔥 SET TO 'true' to develop locally. SET TO 'false' to use live Render server.
  static const bool useLocalBackup = false;

  // ─── Base URL Getter ───────────────────────────────────────────────────────
  static String get baseUrl {
    if (!useLocalBackup) {
      return "https://bahirlink-backend-1.onrender.com";
    }
    if (kIsWeb) {
      return "http://localhost:5000";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:5000"; // Android Emulator address
    } else {
      return "http://localhost:5000"; // iOS Simulator or Desktop
    }
  }

  // ─── Get User Profile ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("accessToken");

      if (token == null || token.isEmpty) {
        debugPrint("❌ No token found in SharedPreferences");
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("accessToken");

      if (token == null || token.isEmpty) {
        debugPrint("❌ No token found in SharedPreferences");
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
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("accessToken");
    debugPrint("🔒 Token removed. Logout processed successfully.");
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

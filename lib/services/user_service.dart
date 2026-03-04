import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  /// 🔥 Auto detect base URL
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:5000";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:5000";
    } else {
      return "http://localhost:5000";
    }
  }

  /// Get user profile
  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("accessToken");

      if (token == null || token.isEmpty) {
        print("❌ No token found");
        return null;
      }

      final response = await http.get(
        Uri.parse("$baseUrl/api/users/profile"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("GET STATUS: ${response.statusCode}");
      print("GET BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _normalizeUserData(data['user'] ?? data);
      }

      return null;
    } catch (e) {
      print("GET ERROR: $e");
      return null;
    }
  }

  /// Update user profile
  static Future<Map<String, dynamic>?> updateProfile(
    Map<String, dynamic> updates,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("accessToken");

      if (token == null || token.isEmpty) {
        print("❌ No token found");
        return null;
      }

      final response = await http.put(
        Uri.parse("$baseUrl/api/users/profile"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _normalizeUserData(data['user'] ?? data);
      }

      return null;
    } catch (e) {
      print("UPDATE ERROR: $e");
      return null;
    }
  }

  /// Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("accessToken");
  }

  static Map<String, dynamic> _normalizeUserData(Map<String, dynamic> user) {
    final firstName = user['firstName'] ?? '';
    final lastName = user['lastName'] ?? '';

    return {
      'firstName': firstName,
      'lastName': lastName,
      'name': (firstName + " " + lastName).trim(), // ✅ full name
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

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String baseUrl = "http://localhost:5000";

  /// Get user profile
  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("accessToken") ?? "";

      if (token.isEmpty) {
        return null;
      }

      final url = Uri.parse("$baseUrl/api/users/profile");
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _normalizeUserData(data['user']);
      } else if (response.statusCode == 401) {
        return null;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update user profile
  static Future<Map<String, dynamic>?> updateProfile(
    Map<String, dynamic> updates,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("accessToken") ?? "";

      if (token.isEmpty) {
        return null;
      }

      final url = Uri.parse("$baseUrl/api/users/profile");
      final updatesJson = jsonEncode(updates);

      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: updatesJson,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _normalizeUserData(data['user']);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Logout user: remove stored access token
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("accessToken");
  }

  /// Normalize user data for UI
  static Map<String, dynamic> _normalizeUserData(Map<String, dynamic> user) {
    return {
      'name':
          user['name'] ??
          "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}".trim(),
      'firstName': user['firstName'] ?? '',
      'lastName': user['lastName'] ?? '',
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

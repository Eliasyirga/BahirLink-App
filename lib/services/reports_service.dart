import 'dart:convert';
import 'package:http/http.dart' as http;

class ReportsService {
  static const String baseUrl = "http://localhost:5000/api";

  /// Fetch emergencies for a user
  static Future<List<Map<String, dynamic>>> fetchUserEmergencies(
    String userId,
  ) async {
    final url = Uri.parse("$baseUrl/emergencies/$userId");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse is Map<String, dynamic> &&
          jsonResponse['data'] != null) {
        return List<Map<String, dynamic>>.from(jsonResponse['data']);
      }
      return [];
    } else {
      throw Exception("Failed to load emergencies (${response.statusCode})");
    }
  }

  /// Fetch all emergency types
  static Future<List<Map<String, dynamic>>> fetchEmergencyTypes() async {
    final url = Uri.parse("$baseUrl/emergencyType");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse is Map<String, dynamic> &&
          jsonResponse['emergencyTypes'] != null) {
        return List<Map<String, dynamic>>.from(jsonResponse['emergencyTypes']);
      }
      return [];
    } else {
      throw Exception(
        "Failed to load emergency types (${response.statusCode})",
      );
    }
  }

  /// Fetch all categories
  static Future<List<Map<String, dynamic>>> fetchCategories() async {
    final url = Uri.parse("$baseUrl/categories");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse is Map<String, dynamic> &&
          jsonResponse['data'] != null) {
        return List<Map<String, dynamic>>.from(jsonResponse['data']);
      }
      return [];
    } else {
      throw Exception("Failed to load categories (${response.statusCode})");
    }
  }
}

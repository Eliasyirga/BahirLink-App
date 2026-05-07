import 'dart:convert';
import 'package:http/http.dart'; // Using Client for better performance

class CategoryService {
  static const String baseUrl = "http://localhost:5000/api/categories";

  /// Fetch categories for a specific emergency type ID with Localization
  static Future<List<dynamic>> getCategories(String emergencyTypeId, {String lang = 'en'}) async {
    try {
      final response = await get(
        Uri.parse("$baseUrl/type/$emergencyTypeId"),
        headers: {
          "Content-Type": "application/json",
          "Accept-Language": lang, // 👈 Crucial for your new localization logic
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        
        // Ensure we are grabbing the list from the "data" key
        final List<dynamic> data = decoded["data"] ?? [];
        return data;
      } else {
        // Log the error for better debugging
        print("Backend Error: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Network Error: $e");
      throw Exception("Could not connect to the server.");
    }
  }

  /// Fetch categories specifically for the logged-in agency
  static Future<List<dynamic>> getCategoriesByAgency(String agencyId, {String lang = 'en'}) async {
    final response = await get(
      Uri.parse("$baseUrl/by-agency/$agencyId"),
      headers: {"Accept-Language": lang},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded["data"] ?? [];
    }
    return [];
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ServiceCategoryService {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS, or your IP for physical devices
  static const String baseUrl = "http://localhost:5000/api/serviceCategory";

  /// Fetches service categories based on a specific Service Type ID.
  /// Matches the backend route: GET /api/serviceCategory/:serviceTypeId
  static Future<List<Map<String, dynamic>>> getCategoriesByServiceType(
    String serviceTypeId,
  ) async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/type/$serviceTypeId"))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Your controller returns { success: true, categories: [...] }
        // We prioritize data["categories"], then fallback to data if it's a list
        List<dynamic> rawList = [];
        if (data is Map && data.containsKey("categories")) {
          rawList = data["categories"];
        } else if (data is List) {
          rawList = data;
        }

        return rawList.map((item) {
          return {
            // Handles both MongoDB (_id) and SQL/Standard (id) formats
            "id": item["_id"]?.toString() ?? item["id"]?.toString() ?? "",
            "name": item["name"]?.toString() ?? "Unknown Category",
          };
        }).toList();
      } else {
        debugPrint("ServiceCategory Server Error: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("ServiceCategory Connection Exception: $e");
      return [];
    }
  }
}

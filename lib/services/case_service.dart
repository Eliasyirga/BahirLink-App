import 'dart:convert';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:http/http.dart' as http;

class CaseService {
  // Update this to your machine's IP if testing on a physical device
  static const String _baseUrl = "http://localhost:5000/api/cases";

  static Future<List<dynamic>> getAllCases() async {
    try {
      final response = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        // 1. Check if the backend returned a raw List
        if (data is List) {
          return data;
        }

        // 2. Check if the backend wrapped the list in an object (e.g., {"cases": []})
        if (data is Map<String, dynamic>) {
          if (data.containsKey('cases') && data['cases'] is List) {
            return data['cases'];
          } else if (data.containsKey('data') && data['data'] is List) {
            return data['data'];
          }
        }

        return [];
      } else {
        // Log the error body to see WHY the server is giving a 500 error
        debugPrint("Server Error (${response.statusCode}): ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint("Fetch Exception: $e");
      return [];
    }
  }
}

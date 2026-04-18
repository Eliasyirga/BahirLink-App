import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CaseService {
  // Use 10.0.2.2 instead of localhost if you are using an Android Emulator
  static const String _baseUrl = "http://localhost:5000/api/cases";

  static Future<List<dynamic>> getAllCases() async {
    try {
      final response = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        // Standardizing the response extraction
        return _extractList(data);
      } else {
        debugPrint("Server Error (${response.statusCode}): ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint("Fetch Exception: $e");
      // Rethrow or return empty based on how you want the UI to react
      return [];
    }
  }

  /// Helper to navigate different JSON structures
  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;

    if (data is Map<String, dynamic>) {
      if (data['cases'] is List) return data['cases'];
      if (data['data'] is List) return data['data'];
    }

    debugPrint("Warning: Unexpected JSON format. Could not find a list.");
    return [];
  }
}

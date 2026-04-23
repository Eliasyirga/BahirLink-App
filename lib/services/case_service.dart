import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CaseService {
  static const String _baseUrl = "http://localhost:5000/api/cases";

  static Future<List<dynamic>> getAllCases() async {
    try {
      final response = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        final List<dynamic> allCases = _extractList(data);

        // --- FILTER LOGIC START ---
        // We only keep cases that are NOT 'rejected' and NOT 'resolved'
        final filteredCases = allCases.where((c) {
          final status = (c['status'] ?? '').toString().toLowerCase();
          return status != 'rejected' && status != 'resolved';
        }).toList();
        // --- FILTER LOGIC END ---

        return filteredCases;
      } else {
        debugPrint("Server Error (${response.statusCode}): ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint("Fetch Exception: $e");
      return [];
    }
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      if (data['cases'] is List) return data['cases'];
      if (data['data'] is List) return data['data'];
    }
    return [];
  }
}

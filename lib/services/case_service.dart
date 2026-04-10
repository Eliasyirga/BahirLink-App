// lib/services/case_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class CaseService {
  // CRITICAL: The method must be 'static' to be called without 'new'
  static Future<List<dynamic>> getAllCases() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:5000/api/cases"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

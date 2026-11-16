import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class CaseReportService {
  // 🌍 Dynamic URL Routing
  String get baseUrl => "${ApiConfig.baseUrl}/api/caseReports";

  // -------------------- CREATE REPORT --------------------
  Future<bool> createReport(Map<String, dynamic> reportData) async {
    // Sanitize phone number: Ensure it only contains digits if provided
    if (reportData.containsKey('phoneNumber') &&
        reportData['phoneNumber'] != null) {
      String phone = reportData['phoneNumber'].toString();
      reportData['phoneNumber'] = phone.replaceAll(RegExp(r'\D'), '');
    }

    try {
      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {"Content-Type": "application/json"},
            body: json.encode(reportData),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        debugPrint("Backend Error (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Connection Error: $e");
      return false;
    }
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CaseReportService {
  // 🔥 SET TO 'true' to develop locally. SET TO 'false' to use live Render server.
  static const bool useLocalBackup = false;

  // 🌍 Dynamic URL Routing
  String get baseUrl {
    if (!useLocalBackup) {
      return "https://bahirlink-backend-1.onrender.com/api/caseReports";
    }

    if (kIsWeb) {
      return "http://localhost:5000/api/caseReports";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:5000/api/caseReports";
    } else {
      return "http://localhost:5000/api/caseReports";
    }
  }

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

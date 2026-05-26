import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CaseReportService {
  // 🔥 SET TO 'true' to develop locally. SET TO 'false' to use live Render server.
  static const bool useLocalBackup = false;

  // 🌍 Dynamic URL Routing matching your other core services
  String get baseUrl {
    if (!useLocalBackup) {
      return "https://bahirlink-backend-1.onrender.com/api/caseReports";
    }

    if (kIsWeb) {
      return "http://localhost:5000/api/caseReports";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:5000/api/caseReports"; // Android Emulator address
    } else {
      return "http://localhost:5000/api/caseReports"; // iOS Simulator or Desktop
    }
  }

  // -------------------- CREATE REPORT --------------------
  Future<bool> createReport(Map<String, dynamic> reportData) async {
    try {
      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {"Content-Type": "application/json"},
            body: json.encode(reportData),
          )
          // Increased from 10s to 60s to accommodate Render's free tier sleep cycle wake-up time
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        // Keeps your diagnostic logging intact for validation
        print("Backend Error (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      print("Connection Error: $e");
      return false;
    }
  }
}

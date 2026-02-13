import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/emergency_report_model.dart';

class EmergencyService {
  static const String baseUrl = "http://localhost:5000";

  static Future<bool> sendGuestEmergency(EmergencyReportModel report) async {
    try {
      final url = Uri.parse("$baseUrl/api/emergencies");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(report.toJson()),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error sending emergency: $e");
      return false;
    }
  }
}

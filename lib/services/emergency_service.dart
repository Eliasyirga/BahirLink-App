import 'dart:io';
import 'package:http/http.dart' as http;
import '../model/emergency_report_model.dart';

class EmergencyService {
  static const String baseUrl = "http://localhost:5000";

  /// Send emergency report with optional media file
  static Future<bool> sendGuestEmergency(
    EmergencyReportModel report, {
    File? mediaFile,
  }) async {
    try {
      final uri = Uri.parse("$baseUrl/api/emergencies");

      var request = http.MultipartRequest('POST', uri);

      // Add JSON fields
      report.toJson().forEach((key, value) {
        if (value != null) request.fields[key] = value.toString();
      });

      // Add media file if provided
      if (mediaFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('media', mediaFile.path),
        );
      }

      var response = await request.send();

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error sending emergency: $e");
      return false;
    }
  }
}

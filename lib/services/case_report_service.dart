import 'dart:convert';
import 'dart:io'; // Import for Platform check
import 'package:http/http.dart' as http;

class CaseReportService {
  // 10.0.2.2 is the special alias to your host loopback interface for Android Emulators
  // Use your actual IP address if testing on a physical device
  final String baseUrl = "http://localhost:5000/api/caseReports";

  Future<bool> createReport(Map<String, dynamic> reportData) async {
    try {
      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {"Content-Type": "application/json"},
            body: json.encode(reportData),
          )
          .timeout(const Duration(seconds: 10)); // Added timeout for better UX

      if (response.statusCode == 201) {
        return true;
      } else {
        // This is where you'll see the "Association" error if the backend isn't fixed
        print("Backend Error (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      print("Connection Error: $e");
      return false;
    }
  }
}

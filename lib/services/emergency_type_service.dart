import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/emergency_type.dart'; // FIXED: removed the 's'

class EmergencyTypeService {
  static const String baseUrl = "http://localhost:5000/api/emergencyType";

  static Future<List<EmergencyType>> fetchEmergencyTypes() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Ensure this matches your backend key
      List list = data["emergencyTypes"] ?? [];
      return list.map((e) => EmergencyType.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load emergency types");
    }
  }
}

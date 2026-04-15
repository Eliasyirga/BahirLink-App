import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/service_type.dart';

class ServiceTypeService {
  static const String baseUrl = "http://localhost:5000/api/serviceType";

  static Future<List<ServiceType>> getAllServiceTypes() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List list;
        if (data is List) {
          // If backend returns a raw array: [{}, {}]
          list = data;
        } else {
          // If backend returns a map: {"serviceTypes": [{}, {}]}
          list = data["serviceTypes"] ?? [];
        }

        return list.map((e) => ServiceType.fromJson(e)).toList();
      } else {
        throw Exception("Failed to load service types");
      }
    } catch (e) {
      // Log error and return empty list to prevent UI crash
      print("ServiceTypeService Error: $e");
      return [];
    }
  }
}

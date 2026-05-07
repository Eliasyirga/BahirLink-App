import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../model/service_type.dart';

class ServiceTypeService {
  // Use 10.0.2.2 for Android Emulator, or your machine's IP for physical devices
  static const String baseUrl = "http://localhost:5000/api/serviceType";

  static Future<List<ServiceType>> getAllServiceTypes({String lang = 'en'}) async {
    try {
      // ✅ Append 'lang' as a query parameter
      final Uri url = Uri.parse(baseUrl).replace(queryParameters: {
        'lang': lang,
      });

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Accept-Language': lang,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // ✅ Standardized extraction logic
        if (responseData['success'] == true && responseData['data'] is List) {
          List list = responseData['data'];
          return list
              .map((e) => ServiceType.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else {
        print("❌ ServiceTypeService Error: ${response.statusCode}");
        return [];
      }
    } on SocketException {
      print("❌ Connection Error: Server is unreachable");
      return [];
    } catch (e) {
      print("❌ ServiceTypeService Exception: $e");
      return [];
    }
  }
}
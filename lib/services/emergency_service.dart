import 'dart:typed_data';
import 'dart:io' show File;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

class EmergencyService {
  static const String baseUrl = "http://localhost:5000/api";
  static const String guestEmergencyEndpoint = "$baseUrl/emergencies/guests";

  /// ------------------------
  /// CREATE GUEST + REPORT EMERGENCY
  /// ------------------------
  static Future<Map<String, dynamic>> createGuestEmergency({
    required String contactNo,
    required String kebele,
    required String subdivision,
    String? street,
    String? description,
    required String emergencyTypeId,
    required String categoryId,
    double? latitude,
    double? longitude,
    String? time,
    Uint8List? mediaBytes,
    File? mediaFile,
    String? mediaName,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(guestEmergencyEndpoint),
      );

      // Add basic fields
      request.fields.addAll({
        "contactNo": contactNo,
        "kebele": kebele,
        "subdivision": subdivision,
        if (street != null) "street": street,
        if (description != null) "description": description,
        "emergencyTypeId": emergencyTypeId,
        "categoryId": categoryId,
        "time": time ?? DateTime.now().toIso8601String(),
        if (latitude != null) "latitude": latitude.toString(),
        if (longitude != null) "longitude": longitude.toString(),
      });

      String? detectedMediaType;

      // MEDIA FOR WEB
      if (kIsWeb && mediaBytes != null && mediaName != null) {
        final mimeType =
            lookupMimeType(mediaName) ?? 'application/octet-stream';
        final split = mimeType.split('/');
        detectedMediaType = split.first == "video" ? "video" : "photo";
        request.fields['mediaType'] = detectedMediaType;

        request.files.add(
          http.MultipartFile.fromBytes(
            'media',
            mediaBytes,
            filename: mediaName,
            contentType: MediaType(split[0], split[1]),
          ),
        );
      }

      // MEDIA FOR MOBILE
      if (!kIsWeb && mediaFile != null) {
        final fileName = path.basename(mediaFile.path);
        final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
        final split = mimeType.split('/');
        detectedMediaType = split.first == "video" ? "video" : "photo";
        request.fields['mediaType'] = detectedMediaType;

        request.files.add(
          await http.MultipartFile.fromPath(
            'media',
            mediaFile.path,
            contentType: MediaType(split[0], split[1]),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("HTTP Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception("Failed to create guest emergency: ${response.body}");
      }
    } catch (e) {
      print("createGuestEmergency Error: $e");
      rethrow;
    }
  }
}

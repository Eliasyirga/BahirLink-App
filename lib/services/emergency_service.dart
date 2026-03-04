import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

class EmergencyService {
  // Replace with your backend URL / IP for real devices
  static const String baseUrl = "http://localhost:5000/api";
  static const String guestEndpoint = "$baseUrl/guests/emergencies";

  /// Sends a guest emergency report
  /// [mediaBytes] → for web, [mediaFile] → for mobile
  /// [mediaName] → required if using bytes
  static Future<bool> sendGuestEmergency({
    required Map<String, dynamic> data,
    Uint8List? mediaBytes,
    File? mediaFile,
    String? mediaName,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(guestEndpoint));

      // -----------------------
      // ADD FORM FIELDS
      // -----------------------
      data.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          request.fields[key] = value.toString();
        }
      });

      String? detectedMediaType;

      // -----------------------
      // MEDIA FOR WEB
      // -----------------------
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

      // -----------------------
      // MEDIA FOR MOBILE
      // -----------------------
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

      // -----------------------
      // SEND REQUEST
      // -----------------------
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("HTTP Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      // Backend returns 201 if created successfully
      return response.statusCode == 201;
    } catch (e) {
      print("EmergencyService Error: $e");
      return false;
    }
  }
}

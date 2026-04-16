import 'dart:convert';

class ServiceReportModel {
  final String? id;
  final String serviceTypeId;
  final String serviceCategoryId;
  final String description;
  final int citizenId;
  final int kebeleId; // Changed to int to match backend foreign key
  final String subdivision;
  final String street;
  final double? latitude;
  final double? longitude;
  final DateTime time;
  final String? status;
  final String? mediaUrl;

  ServiceReportModel({
    this.id,
    required this.serviceTypeId,
    required this.serviceCategoryId,
    required this.description,
    required this.citizenId,
    required this.kebeleId,
    required this.subdivision,
    required this.street,
    this.latitude,
    this.longitude,
    required this.time,
    this.status,
    this.mediaUrl,
  });

  /// Converts the Model to a Map for JSON requests
  Map<String, dynamic> toJson() {
    return {
      'serviceTypeId': serviceTypeId,
      'serviceCategoryId': serviceCategoryId,
      'description': description,
      'citizenId': citizenId,
      'kebeleId': kebeleId, // Matches backend Sequelize field
      'subdivision': subdivision,
      'street': street,
      'latitude': latitude,
      'longitude': longitude,
      'time': time.toIso8601String(),
    };
  }

  /// Creates a Model instance from a JSON map (useful for fetching history)
  factory ServiceReportModel.fromJson(Map<String, dynamic> json) {
    return ServiceReportModel(
      id: json['id']?.toString(),
      serviceTypeId: json['serviceTypeId']?.toString() ?? '',
      serviceCategoryId: json['serviceCategoryId']?.toString() ?? '',
      description: json['description'] ?? '',
      citizenId: json['citizenId'] is int
          ? json['citizenId']
          : int.parse(json['citizenId'].toString()),
      kebeleId: json['kebeleId'] is int
          ? json['kebeleId']
          : int.parse(json['kebeleId'].toString()),
      subdivision: json['subdivision'] ?? '',
      street: json['street'] ?? '',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      time: json['time'] != null
          ? DateTime.parse(json['time'])
          : DateTime.now(),
      status: json['status'],
      mediaUrl: json['mediaUrl'],
    );
  }
}

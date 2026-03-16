class EmergencyReportModel {
  final String emergencyTypeId; // UUID
  final String? categoryId; // UUID
  final String description;
  final double? latitude;
  final double? longitude;
  final int? userId;
  final String? kebele;
  final String? subdivision;
  final String? street;
  final DateTime time; // Local DateTime
  final String? mediaUrl; // Optional
  final String? mediaType; // Optional: photo/video/audio

  EmergencyReportModel({
    required this.emergencyTypeId,
    this.categoryId,
    required this.description,
    this.latitude,
    this.longitude,
    this.userId,
    this.kebele,
    this.subdivision,
    this.street,
    DateTime? time,
    this.mediaUrl,
    this.mediaType,
  }) : time = time ?? DateTime.now();

  // JSON to send to backend
  Map<String, dynamic> toJsonForUser() {
    return {
      "emergencyTypeId": emergencyTypeId,
      "categoryId": categoryId,
      "description": description,
      "kebele": kebele ?? "",
      "subdivision": subdivision ?? "",
      "street": street ?? "",
      "userId": userId,
      "time":
          "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}",
      "location": (latitude != null && longitude != null)
          ? "$latitude,$longitude"
          : null,
      "mediaUrl": mediaUrl ?? "",
      "mediaType": mediaType ?? "",
    };
  }
}

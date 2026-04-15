class EmergencyType {
  final String id;
  final String name;
  final String? description;

  EmergencyType({required this.id, required this.name, this.description});

  factory EmergencyType.fromJson(Map<String, dynamic> json) {
    return EmergencyType(
      // MongoDB uses _id. If your API returns 'id', this fallback handles both.
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name']?.toString() ?? 'Unknown',
      description: json['description']?.toString(),
    );
  }
}

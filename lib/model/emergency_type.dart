class EmergencyType {
  final String id;
  final String name;
  final String? description;

  EmergencyType({required this.id, required this.name, this.description});

  factory EmergencyType.fromJson(Map<String, dynamic> json) {
    return EmergencyType(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
}

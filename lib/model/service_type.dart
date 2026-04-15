class ServiceType {
  final String id;
  final String name;
  final String? description;

  ServiceType({required this.id, required this.name, this.description});

  factory ServiceType.fromJson(Map<String, dynamic> json) {
    return ServiceType(
      // Handles both Sequelize/Postgres 'id' and MongoDB '_id'
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name']?.toString() ?? 'Unknown',
      description: json['description']?.toString(),
    );
  }
}

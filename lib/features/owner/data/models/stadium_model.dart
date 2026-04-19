class StadiumModel {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final String address;
  final String city;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;

  const StadiumModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    required this.address,
    required this.city,
    this.latitude,
    this.longitude,
    this.imageUrl,
    required this.isActive,
    required this.createdAt,
  });

  factory StadiumModel.fromJson(Map<String, dynamic> json) {
    return StadiumModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String,
      city: json['city'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'])
          : json['created_at'] as DateTime,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'owner_id': ownerId,
      'name': name,
      'description': description,
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'image_url': null, // No image uploads for MVP
      'is_active': isActive,
    };
  }
}

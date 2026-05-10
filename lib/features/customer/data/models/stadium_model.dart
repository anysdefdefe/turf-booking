class Stadium {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final List<String> amenities;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final double distanceKm;

  const Stadium({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.amenities,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.isActive,
    required this.createdAt,
    required this.distanceKm,
  });
}

class Court {
  final String id;
  final String stadiumId;
  final String stadiumName;
  final String name;
  final String place;
  final String city;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final double pricePerHour;
  final List<String> courtTypes;
  final bool isAvailable;
  final String description;
  final List<String> amenities;
  final String openTime;
  final String closeTime;
  final double distanceKm;

  const Court({
    required this.id,
    required this.stadiumId,
    required this.stadiumName,
    required this.name,
    required this.place,
    required this.city,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.pricePerHour,
    required this.courtTypes,
    required this.isAvailable,
    required this.description,
    required this.amenities,
    required this.openTime,
    required this.closeTime,
    required this.distanceKm,
  });
}

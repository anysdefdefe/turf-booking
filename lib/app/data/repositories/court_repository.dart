import '../models/court_model.dart';

class CourtRepository {
  CourtRepository._();
  static final CourtRepository instance = CourtRepository._();

  final List<Court> _courts = const [
    Court(
      id: '1',
      name: 'Arena Pro Badminton',
      place: 'Andheri Sports Complex',
      city: 'Andheri West',
      imageUrl: 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800&q=80',
      rating: 4.8,
      reviewCount: 234,
      pricePerHour: 600,
      courtTypes: ['Badminton', 'Squash'],
      isAvailable: true,
      description:
      'State-of-the-art badminton facility with 6 professional courts, wooden flooring, and high-speed shuttles. Perfect for casual play and tournaments alike.',
      amenities: ['Parking', 'Changing Room', 'Cafeteria', 'AC Courts', 'Equipment Rental'],
      openTime: '06:00 AM',
      closeTime: '11:00 PM',
      distanceKm: 1.2,
    ),
    Court(
      id: '2',
      name: 'Smash Zone',
      place: 'Powai Lake Area',
      city: 'Powai',
      imageUrl: 'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=800&q=80',
      rating: 4.5,
      reviewCount: 189,
      pricePerHour: 800,
      courtTypes: ['Tennis', 'Padel'],
      isAvailable: true,
      description:
      'Premium outdoor tennis courts with floodlights for night play. Hard-court surface maintained to international standards.',
      amenities: ['Parking', 'Coaching Available', 'Equipment Rental', 'Night Lights'],
      openTime: '05:30 AM',
      closeTime: '10:00 PM',
      distanceKm: 3.5,
    ),
    Court(
      id: '3',
      name: 'Kick & Play Futsal',
      place: 'Goregaon Sports Club',
      city: 'Goregaon East',
      imageUrl: 'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800&q=80',
      rating: 4.6,
      reviewCount: 312,
      pricePerHour: 1200,
      courtTypes: ['Futsal', 'Football'],
      isAvailable: false,
      description:
      'Indoor synthetic-turf futsal arena with 5-a-side and 7-a-side pitches. Fully air-conditioned with professional-grade goals.',
      amenities: ['Parking', 'Changing Room', 'Shower', 'Canteen', 'Scoreboard'],
      openTime: '07:00 AM',
      closeTime: '11:00 PM',
      distanceKm: 5.1,
    ),
    Court(
      id: '4',
      name: 'Court Kings Basketball',
      place: 'Bandra Reclamation',
      city: 'Bandra West',
      imageUrl: 'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800&q=80',
      rating: 4.3,
      reviewCount: 98,
      pricePerHour: 700,
      courtTypes: ['Basketball'],
      isAvailable: true,
      description:
      'Full-size NBA-standard indoor basketball courts. Hardwood flooring, professional ring height and backboards, with seating for spectators.',
      amenities: ['Parking', 'AC', 'Scoreboard', 'Spectator Seating'],
      openTime: '06:00 AM',
      closeTime: '10:00 PM',
      distanceKm: 7.8,
    ),
    Court(
      id: '5',
      name: 'Spike Central Volleyball',
      place: 'Worli Sea Face',
      city: 'Worli',
      imageUrl: 'https://images.unsplash.com/photo-1612872087720-bb876e2e67d1?w=800&q=80',
      rating: 4.7,
      reviewCount: 145,
      pricePerHour: 500,
      courtTypes: ['Volleyball', 'Beach Volleyball'],
      isAvailable: true,
      description:
      'Beachside volleyball courts with sand pits and hard courts. Stunning sea-view backdrop makes every session feel like a vacation.',
      amenities: ['Open Air', 'Night Lights', 'Equipment Rental', 'Refreshments'],
      openTime: '06:00 AM',
      closeTime: '09:00 PM',
      distanceKm: 9.2,
    ),
    Court(
      id: '6',
      name: 'TableTop TT Hub',
      place: 'Malad West Mall Road',
      city: 'Malad West',
      imageUrl: 'https://images.unsplash.com/photo-1609710228159-0fa9bd7c0827?w=800&q=80',
      rating: 4.2,
      reviewCount: 67,
      pricePerHour: 300,
      courtTypes: ['Table Tennis'],
      isAvailable: true,
      description:
      'Dedicated table tennis facility with 10 Stiga-regulation tables in a climate-controlled hall. Great for beginners and pros alike.',
      amenities: ['AC', 'Equipment Rental', 'Coaching', 'Cafeteria'],
      openTime: '09:00 AM',
      closeTime: '10:00 PM',
      distanceKm: 11.4,
    ),
  ];

  List<Court> getAllCourts() => List.unmodifiable(_courts);

  List<String> getAllCities() {
    final cities = _courts.map((c) => c.city).toSet().toList();
    cities.sort();
    return cities;
  }

  List<Court> filterByCities(List<String> cities) {
    if (cities.isEmpty) return getAllCourts();
    return _courts.where((c) => cities.contains(c.city)).toList();
  }

  List<Court> search(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return getAllCourts();
    return _courts
        .where((c) =>
    c.name.toLowerCase().contains(q) ||
        c.place.toLowerCase().contains(q) ||
        c.city.toLowerCase().contains(q) ||
        c.courtTypes.any((t) => t.toLowerCase().contains(q)))
        .toList();
  }
}
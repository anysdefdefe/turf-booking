import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/court_model.dart';
import '../models/stadium_model.dart';

class CourtRepository {
  CourtRepository._(this._client);

  final SupabaseClient _client;

  static final CourtRepository instance = CourtRepository._(
    Supabase.instance.client,
  );

  List<Stadium> _stadiums = const [];
  List<Court> _courts = const [];

  Future<void> refreshCatalog() async {
    final stadiumRows = await _client
        .from('stadiums')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);

    final stadiums = stadiumRows
        .cast<Map<String, dynamic>>()
        .map(_mapStadium)
        .toList(growable: false);
    final stadiumById = {for (final stadium in stadiums) stadium.id: stadium};

    final courtRows = await _client
        .from('courts')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);

    final courts = courtRows
        .cast<Map<String, dynamic>>()
        .map((row) => _mapCourt(row, stadiumById[row['stadium_id'] as String?]))
        .whereType<Court>()
        .toList(growable: false);

    _stadiums = stadiums;
    _courts = courts;
  }

  Future<List<String>> getBookedSlotsForDate({
    required String courtId,
    required DateTime date,
  }) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final dayString = '$date'.split(' ').first;

    List<Map<String, dynamic>> slotRows = const [];
    try {
      slotRows =
          (await _client
                  .from('slots')
                  .select('booking_id, start_time, status')
                  .eq('court_id', courtId)
                  .gte('start_time', _toSqlTimestamp(dayStart))
                  .lt('start_time', _toSqlTimestamp(dayEnd)))
              .cast<Map<String, dynamic>>();
    } on Exception {
      slotRows = const [];
    }

    final bookingRows = await _client
        .from('bookings')
        .select('id, start_time, end_time, status')
        .eq('court_id', courtId)
        .eq('booking_date', dayString);

    final bookingStatusById = <String, String>{};
    for (final raw in bookingRows) {
      final row = raw;
      final bookingId = row['id']?.toString();
      if (bookingId == null || bookingId.isEmpty) {
        continue;
      }
      bookingStatusById[bookingId] =
          row['status']?.toString().toLowerCase() ?? '';
    }

    final booked = <String>{};
    for (final raw in slotRows) {
      final row = raw;
      final status = (row['status'] as String? ?? '').toLowerCase();
      if (status == 'available') {
        continue;
      }

      final bookingId = row['booking_id']?.toString();
      if (bookingId != null && bookingStatusById[bookingId] == 'cancelled') {
        continue;
      }

      final startTime = DateTime.tryParse(row['start_time']?.toString() ?? '');
      if (startTime == null) {
        continue;
      }
      booked.add(_formatTo12Hour(startTime));
    }

    // Fallback source to keep UI in sync even if slot rows were not created.
    // Only use this fallback if no slot rows were found (to avoid filling in-between slots).
    if (booked.isEmpty) {
      for (final raw in bookingRows) {
        final row = raw;
        final status = (row['status']?.toString() ?? '').toLowerCase();
        if (status == 'cancelled') {
          continue;
        }

        final start = _bookingTimeToDateTime(
          dayStart,
          row['start_time']?.toString(),
        );
        if (start == null) {
          continue;
        }

        // Only mark the first slot as booked in fallback (don't fill in-between)
        booked.add(_formatTo12Hour(start));
      }
    }

    return booked.toList(growable: false);
  }

  List<String> generateHourlySlots(Court court) {
    final open = _parseTimeOfDay(court.openTime);
    final close = _parseTimeOfDay(court.closeTime);
    if (open == null || close == null) {
      return const [];
    }

    final baseDate = DateTime(2000, 1, 1);
    var cursor = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      open.hour,
      open.minute,
    );
    final closeDateTime = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      close.hour,
      close.minute,
    );

    final slots = <String>[];
    while (cursor.isBefore(closeDateTime)) {
      slots.add(_formatTo12Hour(cursor));
      cursor = cursor.add(const Duration(hours: 1));
    }
    return slots;
  }

  List<Court> getAllCourts() => List.unmodifiable(_courts);

  List<Stadium> getAllStadiums() => List.unmodifiable(_stadiums);

  Court? getCourtById(String id) {
    for (final court in _courts) {
      if (court.id == id) {
        return court;
      }
    }
    return null;
  }

  Stadium? getStadiumById(String id) {
    for (final stadium in _stadiums) {
      if (stadium.id == id) return stadium;
    }
    return null;
  }

  List<Court> getCourtsByStadium(String stadiumId) {
    return _courts.where((court) => court.stadiumId == stadiumId).toList();
  }

  List<String> getAllCities() {
    final cities = _stadiums.map((s) => s.city).toSet().toList();
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
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.stadiumName.toLowerCase().contains(q) ||
              c.place.toLowerCase().contains(q) ||
              c.city.toLowerCase().contains(q) ||
              c.courtTypes.any((t) => t.toLowerCase().contains(q)),
        )
        .toList();
  }

  String _toSqlTimestamp(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min:$s';
  }

  DateTime? _bookingTimeToDateTime(DateTime date, String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return DateTime(
        date.year,
        date.month,
        date.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
      );
    }

    final parts = value.split(':');
    if (parts.length < 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    final second = parts.length > 2
        ? int.tryParse(parts[2].split('.').first) ?? 0
        : 0;
    return DateTime(date.year, date.month, date.day, hour, minute, second);
  }

  List<String> getAllSports() {
    final sports = <String>{};
    for (final court in _courts) {
      sports.addAll(court.courtTypes);
    }
    final list = sports.toList();
    list.sort();
    return list;
  }

  List<String> getAllTeamSizes() {
    final teamSizes = _courts.map((c) => c.teamSize).toSet().toList();
    teamSizes.sort();
    return teamSizes;
  }

  Stadium _mapStadium(Map<String, dynamic> row) {
    String imageUrl = row['image_url'] as String? ?? '';
    if (imageUrl.isEmpty && row['image_urls'] is List) {
      final urls = row['image_urls'] as List;
      if (urls.isNotEmpty) {
        imageUrl = urls.first.toString();
      }
    }

    return Stadium(
      id: row['id'] as String,
      ownerId: row['owner_id'] as String? ?? '',
      name: row['name'] as String? ?? '',
      description: row['description'] as String? ?? '',
      address: row['address'] as String? ?? '',
      city: row['city'] as String? ?? '',
      latitude: (row['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (row['longitude'] as num?)?.toDouble() ?? 0,
      imageUrl: imageUrl,
      isActive: row['is_active'] as bool? ?? true,
      createdAt:
          DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Court? _mapCourt(Map<String, dynamic> row, Stadium? stadium) {
    if (stadium == null) {
      return null;
    }

    final sportRaw =
        row['sport_type'] as String? ?? row['sport'] as String? ?? '';
    final courtTypes = sportRaw
        .split(RegExp(r'[,/]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    final amenitiesRaw = row['amenities'];
    final amenities = amenitiesRaw is List
        ? amenitiesRaw.map((e) => e.toString()).toList(growable: false)
        : <String>[];

    String imageUrl = row['image_url'] as String? ?? '';
    if (imageUrl.isEmpty && row['image_urls'] is List) {
      final urls = row['image_urls'] as List;
      if (urls.isNotEmpty) {
        imageUrl = urls.first.toString();
      }
    }

    final openTime = _formatTimeString(row['open_time']?.toString());
    final closeTime = _formatTimeString(row['close_time']?.toString());

    return Court(
      id: row['id'] as String,
      stadiumId: row['stadium_id'] as String? ?? stadium.id,
      stadiumName: stadium.name,
      name: row['name'] as String? ?? 'Court',
      place: stadium.address,
      city: stadium.city,
      imageUrl: imageUrl.isEmpty ? stadium.imageUrl : imageUrl,
      pricePerHour:
          (row['price_per_hour'] as num?)?.toDouble() ??
          (row['hourly_rate'] as num?)?.toDouble() ??
          0,
      courtTypes: courtTypes.isEmpty ? const ['Court'] : courtTypes,
      isAvailable: row['is_active'] as bool? ?? true,
      description: row['description'] as String? ?? '',
      amenities: amenities,
      openTime: openTime,
      closeTime: closeTime,
      distanceKm: 0,
      teamSize: _defaultTeamSizeForSport(
        courtTypes.isEmpty ? 'Court' : courtTypes.first,
      ),
    );
  }

  String _defaultTeamSizeForSport(String sport) {
    final key = sport.toLowerCase();
    if (key.contains('badminton') ||
        key.contains('tennis') ||
        key.contains('squash')) {
      return 'Singles';
    }
    if (key.contains('basketball')) {
      return '5v5';
    }
    if (key.contains('football') || key.contains('futsal')) {
      return '5v5';
    }
    if (key.contains('volleyball')) {
      return '6v6';
    }
    if (key.contains('cricket')) {
      return 'Practice Net';
    }
    return 'Standard';
  }

  String _formatTimeString(String? source) {
    final parsed = _parseTimeOfDay(source);
    if (parsed == null) {
      return '06:00 AM';
    }
    final temp = DateTime(2000, 1, 1, parsed.hour, parsed.minute);
    return _formatTo12Hour(temp);
  }

  _SimpleTime? _parseTimeOfDay(String? source) {
    if (source == null || source.isEmpty) {
      return null;
    }

    final meridiemMatch = RegExp(
      r'^(\d{1,2}):(\d{2})\s*([APap][Mm])$',
    ).firstMatch(source.trim());
    if (meridiemMatch != null) {
      final hourRaw = int.tryParse(meridiemMatch.group(1)!);
      final minute = int.tryParse(meridiemMatch.group(2)!);
      final meridiem = meridiemMatch.group(3)!.toUpperCase();
      if (hourRaw != null && minute != null) {
        var hour = hourRaw % 12;
        if (meridiem == 'PM') {
          hour += 12;
        }
        return _SimpleTime(hour: hour, minute: minute);
      }
    }

    final direct = DateTime.tryParse('2000-01-01T$source');
    if (direct != null) {
      return _SimpleTime(hour: direct.hour, minute: direct.minute);
    }

    final parts = source.split(':');
    if (parts.length < 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    return _SimpleTime(hour: hour, minute: minute);
  }

  String _formatTo12Hour(DateTime dt) {
    var hour = dt.hour;
    final minute = dt.minute;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) {
      hour = 12;
    }
    final minuteText = minute.toString().padLeft(2, '0');
    final hourText = hour.toString().padLeft(2, '0');
    return '$hourText:$minuteText $suffix';
  }
}

class _SimpleTime {
  final int hour;
  final int minute;

  const _SimpleTime({required this.hour, required this.minute});
}

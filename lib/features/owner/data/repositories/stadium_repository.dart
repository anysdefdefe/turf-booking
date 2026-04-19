import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

import 'package:turf_booking/features/owner/data/models/stadium_model.dart';
import 'package:turf_booking/features/owner/data/models/court_model.dart';
import 'package:turf_booking/shared/exceptions/app_exceptions.dart';

part 'stadium_repository.g.dart';

class StadiumRepository {
  final SupabaseClient _client;

  StadiumRepository(this._client);

  // ── READ ─────────────────────────────────────────────────────────

  /// Returns the single stadium owned by the current user, or null if
  /// no stadium exists yet. RLS policy `owners_select_own_stadiums`
  /// guarantees only the owner's row is visible.
  Future<StadiumModel?> getMyStadium() async {
    try {
      final userId = _client.auth.currentUser!.id;
      final response = await _client
          .from('stadiums')
          .select()
          .eq('owner_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return StadiumModel.fromJson(response);
    } catch (e) {
      throw UnknownException('Failed to fetch stadium: $e', e);
    }
  }

  /// Returns all courts belonging to a given stadium.
  /// RLS policy `owners_select_own_courts` enforces ownership.
  Future<List<CourtModel>> getCourtsForStadium(String stadiumId) async {
    try {
      final response = await _client
          .from('courts')
          .select()
          .eq('stadium_id', stadiumId)
          .order('created_at');

      return response.map((json) => CourtModel.fromJson(json)).toList();
    } catch (e) {
      throw UnknownException('Failed to fetch courts: $e', e);
    }
  }

  // ── WRITE ────────────────────────────────────────────────────────

  /// Creates a stadium and its courts in a pseudo-transactional manner.
  ///
  /// **Transactional Safety:**
  /// Supabase client SDK does not support multi-table transactions.
  /// We compensate by:
  ///   1. Inserting the stadium first
  ///   2. Inserting courts in a batch
  ///   3. If court insertion fails, we DELETE the orphaned stadium
  ///      to prevent a partial state in the database.
  ///
  /// [openTime] and [closeTime] are the stadium-level operating hours
  /// from the UI. They are applied to EVERY court during insertion,
  /// satisfying the `NOT NULL` constraint on `courts.open_time` and
  /// `courts.close_time` without requiring a schema migration.
  Future<StadiumModel> createStadiumWithCourts({
    required String name,
    String? description,
    List<String> amenities = const [],
    required String address,
    required String city,
    double? latitude,
    double? longitude,
    required String openTime,
    required String closeTime,
    required List<CourtInsertPayload> courts,
  }) async {
    final userId = _client.auth.currentUser!.id;

    // ── Step 1: Insert Stadium ────────────────────────────────────
    late final StadiumModel stadium;
    try {
      final stadiumResponse = await _client
          .from('stadiums')
          .insert({
            'owner_id': userId,
            'name': name,
            'description': description,
            'amenities': amenities,
            'address': address,
            'city': city,
            'latitude': latitude,
            'longitude': longitude,
            'image_url': null,
            'is_active': true,
          })
          .select()
          .single();

      stadium = StadiumModel.fromJson(stadiumResponse);
    } catch (e) {
      throw UnknownException('Failed to create stadium: $e', e);
    }

    // ── Step 2: Insert Courts (batch) ─────────────────────────────
    try {
      final courtPayloads = courts.map((court) => {
        'stadium_id': stadium.id,
        'name': court.name,
        'sport_type': court.sportType,
        'description': court.description,
        'price_per_hour': court.pricePerHour,
        'image_url': null,
        'equipments': court.equipments,
        'open_time': openTime,  // Stadium-level timing cascaded
        'close_time': closeTime, // Stadium-level timing cascaded
        'is_active': true,
      }).toList();

      await _client.from('courts').insert(courtPayloads);
    } catch (e) {
      // ── Step 3: Compensating Delete ─────────────────────────────
      // Courts failed. Remove the orphan stadium to prevent partial state.
      try {
        await _client.from('stadiums').delete().eq('id', stadium.id);
      } catch (_) {
        // If even cleanup fails, we still throw the original error.
        // The admin can manually reconcile orphaned rows.
      }
      throw UnknownException(
        'Failed to create courts. Stadium insertion was rolled back: $e', e,
      );
    }

    return stadium;
  }

  // ── CREATE (single court) ─────────────────────────────────────────

  /// Inserts a single court into an existing stadium.
  Future<CourtModel> addCourt({
    required String stadiumId,
    required String name,
    required String sportType,
    String? description,
    required double pricePerHour,
    List<String> equipments = const [],
    required String openTime,
    required String closeTime,
  }) async {
    try {
      final response = await _client
          .from('courts')
          .insert({
            'stadium_id': stadiumId,
            'name': name,
            'sport_type': sportType,
            'description': description,
            'price_per_hour': pricePerHour,
            'image_url': null,
            'equipments': equipments,
            'open_time': openTime,
            'close_time': closeTime,
            'is_active': true,
          })
          .select()
          .single();
      return CourtModel.fromJson(response);
    } catch (e) {
      throw UnknownException('Failed to add court: $e', e);
    }
  }

  /// Hard-deletes a court by ID.
  Future<void> deleteCourt(String courtId) async {
    try {
      await _client.from('courts').delete().eq('id', courtId);
    } catch (e) {
      throw UnknownException('Failed to delete court: $e', e);
    }
  }

  // ── UPDATE ───────────────────────────────────────────────────────

  /// Toggles the `is_active` flag on a stadium.
  Future<void> toggleStadiumActive(String stadiumId, bool isActive) async {
    try {
      await _client
          .from('stadiums')
          .update({'is_active': isActive})
          .eq('id', stadiumId);
    } catch (e) {
      throw UnknownException('Failed to update stadium status: $e', e);
    }
  }

  /// Updates mutable fields on a stadium. Only non-null values are sent.
  Future<void> updateStadium({
    required String stadiumId,
    String? name,
    String? description,
    List<String>? amenities,
    String? address,
    String? city,
    bool? isActive,
  }) async {
    try {
      final Map<String, dynamic> payload = {};
      if (name != null) payload['name'] = name;
      if (description != null) payload['description'] = description;
      if (amenities != null) payload['amenities'] = amenities;
      if (address != null) payload['address'] = address;
      if (city != null) payload['city'] = city;
      if (isActive != null) payload['is_active'] = isActive;

      if (payload.isEmpty) return;

      await _client.from('stadiums').update(payload).eq('id', stadiumId);
    } catch (e) {
      throw UnknownException('Failed to update stadium: $e', e);
    }
  }

  /// Updates mutable fields on a court. Only non-null values are sent.
  Future<void> updateCourt({
    required String courtId,
    String? name,
    String? sportType,
    String? description,
    double? pricePerHour,
    List<String>? equipments,
    String? openTime,
    String? closeTime,
    bool? isActive,
  }) async {
    try {
      final Map<String, dynamic> payload = {};
      if (name != null) payload['name'] = name;
      if (sportType != null) payload['sport_type'] = sportType;
      if (description != null) payload['description'] = description;
      if (pricePerHour != null) payload['price_per_hour'] = pricePerHour;
      if (equipments != null) payload['equipments'] = equipments;
      if (openTime != null) payload['open_time'] = openTime;
      if (closeTime != null) payload['close_time'] = closeTime;
      if (isActive != null) payload['is_active'] = isActive;

      if (payload.isEmpty) return;

      await _client.from('courts').update(payload).eq('id', courtId);
    } catch (e) {
      throw UnknownException('Failed to update court: $e', e);
    }
  }

  /// Creates a maintenance 'phantom' booking by inserting into `slots`.
  /// The `booking_id` is left null and `status` is 'maintenance'.
  Future<void> createMaintenanceSlot({
    required String courtId,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) async {
    try {
      final start = DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute);
      final end = DateTime(date.year, date.month, date.day, endTime.hour, endTime.minute);

      if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
        throw Exception('End time must be after start time.');
      }

      final inserts = <Map<String, dynamic>>[];
      var cursor = start;
      while (cursor.isBefore(end)) {
        final nextCursor = cursor.add(const Duration(hours: 1));
        
        final stStr = '${cursor.year.toString().padLeft(4, '0')}-${cursor.month.toString().padLeft(2, '0')}-${cursor.day.toString().padLeft(2, '0')} ${cursor.hour.toString().padLeft(2, '0')}:${cursor.minute.toString().padLeft(2, '0')}:00';
        final etStr = '${nextCursor.year.toString().padLeft(4, '0')}-${nextCursor.month.toString().padLeft(2, '0')}-${nextCursor.day.toString().padLeft(2, '0')} ${nextCursor.hour.toString().padLeft(2, '0')}:${nextCursor.minute.toString().padLeft(2, '0')}:00';

        inserts.add({
          'court_id': courtId,
          'start_time': stStr,
          'end_time': etStr,
          'status': 'maintenance',
          'booking_id': null,
        });

        cursor = nextCursor;
      }

      await _client.from('slots').insert(inserts);
    } catch (e) {
      throw UnknownException('Failed to create maintenance slot: $e', e);
    }
  }
}

/// A lightweight DTO for court data collected from the UI form.
/// This is NOT a database model — it's a transfer object consumed
/// only by [StadiumRepository.createStadiumWithCourts].
class CourtInsertPayload {
  final String name;
  final String sportType;
  final String? description;
  final double pricePerHour;
  final List<String> equipments;

  const CourtInsertPayload({
    required this.name,
    required this.sportType,
    this.description,
    required this.pricePerHour,
    this.equipments = const [],
  });
}

@riverpod
StadiumRepository stadiumRepository(Ref ref) {
  return StadiumRepository(Supabase.instance.client);
}

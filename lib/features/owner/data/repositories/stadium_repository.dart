import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        'amenities': court.amenities,
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
}

/// A lightweight DTO for court data collected from the UI form.
/// This is NOT a database model — it's a transfer object consumed
/// only by [StadiumRepository.createStadiumWithCourts].
class CourtInsertPayload {
  final String name;
  final String sportType;
  final String? description;
  final double pricePerHour;
  final List<String> amenities;

  const CourtInsertPayload({
    required this.name,
    required this.sportType,
    this.description,
    required this.pricePerHour,
    this.amenities = const [],
  });
}

@riverpod
StadiumRepository stadiumRepository(Ref ref) {
  return StadiumRepository(Supabase.instance.client);
}

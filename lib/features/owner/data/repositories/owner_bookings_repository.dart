import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:turf_booking/features/owner/data/models/booking_model.dart';
import 'package:turf_booking/shared/exceptions/app_exceptions.dart';

part 'owner_bookings_repository.g.dart';

class OwnerBookingsRepository {
  final SupabaseClient _client;

  OwnerBookingsRepository(this._client);

  /// Fetches all bookings for the given [stadiumId].
  ///
  /// Step 1 – fetch bookings (with court/customer joins).
  /// Step 2 – fetch individual slots grouped by booking_id in a separate query.
  ///           This mirrors what the customer-side repository does and gracefully
  ///           handles the case where the owner does not yet have an RLS policy
  ///           on the slots table (returns empty slot list, UI falls back).
  Future<List<BookingModel>> getBookingsForStadium(String stadiumId) async {
    try {
      // ── 1. Bookings ──────────────────────────────────────────────────────────
      final response = await _client.from('bookings').select('''
        *,
        courts!inner (
          name,
          stadium_id,
          stadium:stadiums (
            name
          )
        ),
        customer:users (
          full_name,
          phone
        )
      ''')
      .eq('courts.stadium_id', stadiumId)
      .order('booking_date', ascending: false)
      .order('start_time', ascending: false);

      final rows = response as List<dynamic>;

      // ── 2. Individual slots ──────────────────────────────────────────────────
      // Collect all booking IDs so we can fetch their slots in one round-trip.
      final bookingIds = rows
          .cast<Map<String, dynamic>>()
          .map((r) => r['id'] as String)
          .toList(growable: false);

      // Map: bookingId → list of slot rows
      Map<String, List<Map<String, dynamic>>> slotsByBooking = {};

      if (bookingIds.isNotEmpty) {
        try {
          final slotRows = await _client
              .from('slots')
              .select('id, booking_id, start_time, end_time, status')
              .inFilter('booking_id', bookingIds);

          for (final raw in slotRows as List<dynamic>) {
            final row = raw as Map<String, dynamic>;
            final bookingId = row['booking_id'] as String?;
            if (bookingId == null) continue;
            slotsByBooking.putIfAbsent(bookingId, () => []).add(row);
          }
        } on PostgrestException catch (e) {
          // If the owner does not yet have an RLS policy that allows reading
          // slots, Supabase returns a 42501 / row-level security error.
          // We silently swallow it here so the bookings list still renders —
          // the UI will fall back to displaying the booking-level time range.
          final msg = e.message.toLowerCase();
          final isRlsError =
              (e.code == '42501' || msg.contains('row-level security')) &&
              msg.contains('slots');
          if (!isRlsError) rethrow;
        } catch (_) {
          // Any other slot-fetch error should not crash the bookings screen.
        }
      }

      // ── 3. Assemble models ───────────────────────────────────────────────────
      return rows.map((json) {
        final map = json as Map<String, dynamic>;
        final bookingId = map['id'] as String;

        // Attach the slot rows for this booking (empty list if none / RLS blocked).
        map['slots'] = slotsByBooking[bookingId] ?? const <Map<String, dynamic>>[];

        return BookingModel.fromJson(map);
      }).toList();
    } catch (e) {
      throw UnknownException('Failed to fetch bookings: $e', e);
    }
  }
}

@riverpod
OwnerBookingsRepository ownerBookingsRepository(Ref ref) {
  return OwnerBookingsRepository(Supabase.instance.client);
}

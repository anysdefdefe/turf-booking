import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:turf_booking/features/owner/data/models/booking_model.dart';
import 'package:turf_booking/shared/exceptions/app_exceptions.dart';

part 'owner_bookings_repository.g.dart';

class OwnerBookingsRepository {
  final SupabaseClient _client;

  OwnerBookingsRepository(this._client);

  /// Uses the `owners_select_court_bookings` RLS policy to fetch bookings
  /// specifically scoped to courts owned by the currently authenticated user.
  Future<List<BookingModel>> getMyBookings() async {
    try {
      final response = await _client.from('bookings').select('''
        *,
        courts (
          name,
          stadium:stadiums (
            name
          )
        ),
        customer:users (
          full_name
        )
      ''').order('booking_date', ascending: false).order('start_time', ascending: false);

      return (response as List<dynamic>)
          .map((json) => BookingModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw UnknownException('Failed to fetch bookings: $e', e);
    }
  }
}

@riverpod
OwnerBookingsRepository ownerBookingsRepository(Ref ref) {
  return OwnerBookingsRepository(Supabase.instance.client);
}

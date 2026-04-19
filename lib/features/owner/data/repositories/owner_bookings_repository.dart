import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:turf_booking/features/owner/data/models/booking_model.dart';
import 'package:turf_booking/shared/exceptions/app_exceptions.dart';

part 'owner_bookings_repository.g.dart';

class OwnerBookingsRepository {
  final SupabaseClient _client;

  OwnerBookingsRepository(this._client);

  /// Explicitly requests bookings strictly mapped to the provided [stadiumId].
  /// Uses an !inner join to natively filter the parent bookings table via the child relation.
  Future<List<BookingModel>> getBookingsForStadium(String stadiumId) async {
    try {
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
          full_name
        )
      ''')
      .eq('courts.stadium_id', stadiumId)
      .order('booking_date', ascending: false)
      .order('start_time', ascending: false);

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

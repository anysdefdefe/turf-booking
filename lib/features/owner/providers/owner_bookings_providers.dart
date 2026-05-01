import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:turf_booking/features/owner/data/models/booking_model.dart';
import 'package:turf_booking/features/owner/data/repositories/owner_bookings_repository.dart';
import 'package:turf_booking/features/owner/providers/stadium_providers.dart';

part 'owner_bookings_providers.g.dart';

/// Fetches all bookings explicitly scoped to the active stadium.
@riverpod
Future<List<BookingModel>> ownerBookings(Ref ref) async {
  final stadium = await ref.watch(currentStadiumProvider.future);
  if (stadium == null) return [];

  return ref
      .watch(ownerBookingsRepositoryProvider)
      .getBookingsForStadium(stadium.id);
}

/// Extension to compute derived UI stats off the raw booking models cleanly.
extension BookingModelListStats on List<BookingModel> {
  // ISO8601 local date 'YYYY-MM-DD'
  String get _todayDateStr => DateTime.now().toIso8601String().substring(0, 10);

  int get totalBookings => where((b) => b.status != 'cancelled').length;

  double get totalRevenue {
    return where(
      (b) => b.status == 'confirmed',
    ).fold(0.0, (sum, b) => sum + b.totalAmount);
  }

  double get todayRevenue {
    return where(
      (b) => b.bookingDate == _todayDateStr && b.status == 'confirmed',
    ).fold(0.0, (sum, b) => sum + b.totalAmount);
  }

  int get todayBookings {
    return where(
      (b) => b.bookingDate == _todayDateStr && b.status != 'cancelled',
    ).length;
  }

  Map<String, Map<String, dynamic>> get courtStats {
    final Map<String, Map<String, dynamic>> stats = {};
    for (final b in this) {
      if (b.courtName == null) continue;

      stats.putIfAbsent(
        b.courtName!,
        () => {
          'count': 0,
          'revenue': 0.0,
          'stadiumName': b.stadiumName ?? 'Unknown',
        },
      );

      stats[b.courtName!]!['count'] =
          (stats[b.courtName!]!['count'] as int) + 1;

      if (b.status == 'confirmed') {
        stats[b.courtName!]!['revenue'] =
            (stats[b.courtName!]!['revenue'] as double) + b.totalAmount;
      }
    }
    return stats;
  }
}

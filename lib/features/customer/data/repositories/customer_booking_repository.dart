import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/customer_booking.dart';
import 'court_repository.dart';

class BookingConflictException implements Exception {
  final String message;

  BookingConflictException(this.message);

  @override
  String toString() => message;
}

class CustomerBookingRepository {
  CustomerBookingRepository._(this._client);

  final SupabaseClient _client;

  static final CustomerBookingRepository instance = CustomerBookingRepository._(
    Supabase.instance.client,
  );

  final CourtRepository _courtRepo = CourtRepository.instance;
  final List<CustomerBooking> _bookings = [];
  final ValueNotifier<List<CustomerBooking>> bookingsNotifier =
      ValueNotifier<List<CustomerBooking>>(const []);

  void _syncNotifier() {
    bookingsNotifier.value = List<CustomerBooking>.unmodifiable(_bookings);
  }

  Future<void> fetchUserBookings() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      _bookings.clear();
      _syncNotifier();
      return;
    }

    await _courtRepo.refreshCatalog();

    final bookingRows = await _client
        .from('bookings')
        .select(
          'id, court_id, booking_date, start_time, end_time, status, payment_status, created_at',
        )
        .eq('customer_id', user.id)
        .order('created_at', ascending: false);

    final bookingIds = bookingRows
        .cast<Map<String, dynamic>>()
        .map((row) => row['id'] as String)
        .toList(growable: false);

    if (bookingIds.isEmpty) {
  }


    final mapped = <CustomerBooking>[];
    for (final raw in bookingRows) {
      final row = raw;
      final courtId = row['court_id'] as String?;
      if (courtId == null) {
        continue;
      }
      final court = _courtRepo.getCourtById(courtId);
      if (court == null) {
        continue;
      }

      final bookingId = row['id'] as String;
      final fallbackStartLabel = _slotLabelFromIso(
        row['start_time']?.toString(),
      );
      final slots = fallbackStartLabel.isNotEmpty ? [fallbackStartLabel] : <String>[];

      final bookingDate =
          DateTime.tryParse(row['booking_date']?.toString() ?? '') ??
          DateTime.now();
      final bookedSlotCount = (row['duration_hours'] as num?)?.toInt();

      mapped.add(
        CustomerBooking(
          id: bookingId,
          court: court,
          status: _statusFromRaw(
            row['status']?.toString(),
            row['payment_status']?.toString(),
          ),
          date: bookingDate,
          createdAt:
              DateTime.tryParse(row['created_at']?.toString() ?? '') ??
              bookingDate,
          slots: slots,
          courtType: court.courtTypes.first,
          cancelledAt: row['status']?.toString() == 'cancelled'
              ? DateTime.tryParse(row['created_at']?.toString() ?? '')
              : null,
          bookedSlotCount: bookedSlotCount,
          firstSlotLabel: slots.isEmpty ? fallbackStartLabel : null,
        ),
      );
    }

    _bookings
      ..clear()
      ..addAll(mapped);
    _syncNotifier();
  }

  List<CustomerBooking> getAllBookings() {
    if (_bookings.isEmpty) {
      fetchUserBookings();
    }
    return List.unmodifiable(_bookings);
  }

  List<CustomerBooking> getByStatus(BookingStatus status) {
    return _bookings.where((booking) => booking.status == status).toList();
  }

  Future<void> cancelBooking(String bookingId) async {
    final index = _bookings.indexWhere((booking) => booking.id == bookingId);
    if (index == -1) {
      return;
    }
    final booking = _bookings[index];
    if (!booking.canCancel) {
      return;
    }

    await _client
        .from('bookings')
        .update({'status': 'cancelled', 'payment_status': 'refunded'})
        .eq('id', bookingId);

    _bookings[index] = booking.copyWith(
      status: BookingStatus.cancelled,
      cancelledAt: DateTime.now(),
    );
    _syncNotifier();
  }

  Future<void> addBooking(CustomerBooking booking) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return;
    }

    final date = DateTime(
      booking.date.year,
      booking.date.month,
      booking.date.day,
    );
    final slotTimes =
        booking.slots
            .map((slot) => _slotLabelToDateTime(date, slot))
            .whereType<DateTime>()
            .toList()
          ..sort();

    await _ensureBookingSlotAvailability(
      courtId: booking.court.id,
      date: date,
      slotTimes: slotTimes,
    );

    final bookingPayload = {
      'court_id': booking.court.id,
      'customer_id': user.id,
      'booking_date': date.toIso8601String().split('T').first,
      'start_time': slotTimes.isEmpty ? null : _toPostgresTime(slotTimes.first),
      'end_time': slotTimes.isEmpty
          ? null
          : _toPostgresTime(slotTimes.last.add(const Duration(hours: 1))),
      'duration_hours': booking.durationHours,
      'total_amount': booking.totalAmount,
      'status': booking.status == BookingStatus.cancelled
          ? 'cancelled'
          : 'confirmed',
      'payment_status': booking.status == BookingStatus.cancelled
          ? 'unpaid'
          : 'paid',
    };

    await _client
        .from('bookings')
        .insert(bookingPayload)
        .select('id')
        .single();
    // No slots table insertion required as we save one slot per booking row directly.

    _bookings.insert(0, booking.copyWith(status: BookingStatus.booked));
    _syncNotifier();
  }

  Future<void> _ensureBookingSlotAvailability({
    required String courtId,
    required DateTime date,
    required List<DateTime> slotTimes,
  }) async {
    if (slotTimes.isEmpty) {
      return;
    }

    final day = date.toIso8601String().split('T').first;
    final existingRows = await _client
        .from('bookings')
        .select('id, status, booking_date, start_time, end_time')
        .eq('court_id', courtId)
        .eq('booking_date', day);

    final requestedStart = slotTimes.first;
    final requestedEnd = slotTimes.last.add(const Duration(hours: 1));

    for (final raw in existingRows) {
      final row = raw;
      final existingStart = _bookingTimeToDateTime(
        date,
        row['start_time']?.toString(),
      );
      final existingEnd = _bookingTimeToDateTime(
        date,
        row['end_time']?.toString(),
      );

      if (existingStart == null || existingEnd == null) {
        continue;
      }

      final overlaps =
          requestedStart.isBefore(existingEnd) &&
          requestedEnd.isAfter(existingStart);
      if (!overlaps) {
        continue;
      }

      final existingStatus = row['status']?.toString() ?? 'unknown';
      throw BookingConflictException(
        'Selected slot is already booked for this court. Existing booking status: $existingStatus.',
      );
    }
  }

  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    final dbStatus = status == BookingStatus.cancelled
        ? 'cancelled'
        : 'confirmed';
    final paymentStatus = status == BookingStatus.cancelled
        ? 'refunded'
        : 'paid';

    await _client
        .from('bookings')
        .update({'status': dbStatus, 'payment_status': paymentStatus})
        .eq('id', bookingId);

    final index = _bookings.indexWhere((booking) => booking.id == bookingId);
    if (index == -1) {
      return;
    }
    _bookings[index] = _bookings[index].copyWith(status: status);
    _syncNotifier();
  }

  BookingStatus _statusFromRaw(String? status, String? paymentStatus) {
    if ((status ?? '').toLowerCase() == 'cancelled') {
      return BookingStatus.cancelled;
    }
    if ((status ?? '').toLowerCase() == 'pending' ||
        (paymentStatus ?? '').toLowerCase() == 'unpaid') {
      return BookingStatus.unpaid;
    }
    return BookingStatus.booked;
  }

  String _slotLabelFromIso(String? iso) {
    if (iso == null || iso.isEmpty) {
      return '';
    }
    final dt = DateTime.tryParse(iso);
    if (dt == null) {
      return '';
    }
    return _formatTo12Hour(dt);
  }

  DateTime? _slotLabelToDateTime(DateTime date, String slot) {
    final parts = slot.split(' ');
    if (parts.length != 2) {
      return null;
    }
    final hm = parts[0].split(':');
    if (hm.length != 2) {
      return null;
    }

    final hourRaw = int.tryParse(hm[0]);
    final minute = int.tryParse(hm[1]);
    if (hourRaw == null || minute == null) {
      return null;
    }

    var hour = hourRaw % 12;
    if (parts[1].toUpperCase() == 'PM') {
      hour += 12;
    }

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  DateTime? _bookingTimeToDateTime(DateTime date, String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final parsedTimestamp = DateTime.tryParse(value);
    if (parsedTimestamp != null) {
      return DateTime(
        date.year,
        date.month,
        date.day,
        parsedTimestamp.hour,
        parsedTimestamp.minute,
        parsedTimestamp.second,
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

  String _toPostgresTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

}

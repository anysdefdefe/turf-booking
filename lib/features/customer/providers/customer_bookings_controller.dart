import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/models/customer_booking.dart';
import 'customer_providers.dart';

part 'customer_bookings_controller.g.dart';

@riverpod
class CustomerBookingsController extends _$CustomerBookingsController {
  @override
  FutureOr<void> build() async {
    await ref.read(customerBookingRepositoryProvider).fetchUserBookings();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(customerBookingRepositoryProvider).fetchUserBookings(),
    );
  }

  Future<void> cancelBooking(CustomerBooking booking) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(customerBookingRepositoryProvider).cancelBooking(booking.id),
    );
  }
}

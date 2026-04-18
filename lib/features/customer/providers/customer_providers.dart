import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:turf_booking/features/customer/data/repositories/court_repository.dart';
import 'package:turf_booking/features/customer/data/repositories/customer_booking_repository.dart';

part 'customer_providers.g.dart';

@riverpod
CourtRepository courtRepository(Ref ref) {
  return CourtRepository.instance;
}

@riverpod
CustomerBookingRepository customerBookingRepository(Ref ref) {
  return CustomerBookingRepository.instance;
}

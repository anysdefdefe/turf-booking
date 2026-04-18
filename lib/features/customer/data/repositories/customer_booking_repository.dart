import '../models/customer_booking.dart';
import 'court_repository.dart';

class CustomerBookingRepository {
  CustomerBookingRepository._();

  static final CustomerBookingRepository instance =
      CustomerBookingRepository._();

  final CourtRepository _courtRepo = CourtRepository.instance;
  final List<CustomerBooking> _bookings = [];

  void _bootstrapIfNeeded() {
    if (_bookings.isNotEmpty) {
      return;
    }
    final courts = _courtRepo.getAllCourts();
    _bookings.addAll([
      CustomerBooking(
        id: 'BK-1001',
        court: courts[0],
        status: BookingStatus.booked,
        date: DateTime.now().add(const Duration(days: 1)),
        slots: const ['07:00 PM', '08:00 PM'],
        courtType: courts[0].courtTypes.first,
      ),
      CustomerBooking(
        id: 'BK-1002',
        court: courts[2],
        status: BookingStatus.booked,
        date: DateTime.now().subtract(const Duration(days: 2)),
        slots: const ['06:00 PM'],
        courtType: courts[2].courtTypes.first,
      ),
      CustomerBooking(
        id: 'BK-1003',
        court: courts[4],
        status: BookingStatus.cancelled,
        date: DateTime.now().add(const Duration(days: 3)),
        slots: const ['08:00 AM', '09:00 AM'],
        courtType: courts[4].courtTypes.first,
        cancelledAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      CustomerBooking(
        id: 'BK-1004',
        court: courts[1],
        status: BookingStatus.booked,
        date: DateTime.now().add(const Duration(days: 2)),
        slots: const ['09:00 PM'],
        courtType: courts[1].courtTypes.first,
      ),
    ]);
  }

  List<CustomerBooking> getAllBookings() {
    _bootstrapIfNeeded();
    return List.unmodifiable(_bookings);
  }

  List<CustomerBooking> getByStatus(BookingStatus status) {
    return _bookings.where((booking) => booking.status == status).toList();
  }

  void cancelBooking(String bookingId) {
    _bootstrapIfNeeded();
    final index = _bookings.indexWhere((booking) => booking.id == bookingId);
    if (index == -1) {
      return;
    }
    final booking = _bookings[index];
    if (!booking.canCancel) {
      return;
    }
    _bookings[index] = booking.copyWith(
      status: BookingStatus.cancelled,
      cancelledAt: DateTime.now(),
    );
  }

  void addBooking(CustomerBooking booking) {
    _bootstrapIfNeeded();
    _bookings.insert(0, booking);
  }

  void updateBookingStatus(String bookingId, BookingStatus status) {
    _bootstrapIfNeeded();
    final index = _bookings.indexWhere((booking) => booking.id == bookingId);
    if (index == -1) {
      return;
    }
    _bookings[index] = _bookings[index].copyWith(status: status);
  }
}

import '../models/customer_booking.dart';
import 'court_repository.dart';

class CustomerBookingRepository {
  CustomerBookingRepository._();

  static final CustomerBookingRepository instance =
      CustomerBookingRepository._();

  final CourtRepository _courtRepo = CourtRepository.instance;

  List<CustomerBooking> getAllBookings() {
    final courts = _courtRepo.getAllCourts();
    return [
      CustomerBooking(
        id: 'BK-1001',
        court: courts[0],
        status: BookingStatus.pending,
        date: DateTime.now().add(const Duration(days: 1)),
        timeSlot: '07:00 PM',
        courtType: courts[0].courtTypes.first,
        durationHours: 2,
      ),
      CustomerBooking(
        id: 'BK-1002',
        court: courts[2],
        status: BookingStatus.approved,
        date: DateTime.now().subtract(const Duration(days: 2)),
        timeSlot: '06:00 PM',
        courtType: courts[2].courtTypes.first,
        durationHours: 1,
      ),
      CustomerBooking(
        id: 'BK-1003',
        court: courts[4],
        status: BookingStatus.pending,
        date: DateTime.now().add(const Duration(days: 3)),
        timeSlot: '08:00 AM',
        courtType: courts[4].courtTypes.first,
        durationHours: 2,
      ),
      CustomerBooking(
        id: 'BK-1004',
        court: courts[1],
        status: BookingStatus.approved,
        date: DateTime.now().subtract(const Duration(days: 6)),
        timeSlot: '09:00 PM',
        courtType: courts[1].courtTypes.first,
        durationHours: 1,
      ),
    ];
  }

  List<CustomerBooking> getByStatus(BookingStatus status) {
    return getAllBookings()
        .where((booking) => booking.status == status)
        .toList();
  }
}

import 'court_model.dart';

enum BookingStatus { pending, approved }

class CustomerBooking {
  final String id;
  final Court court;
  final BookingStatus status;
  final DateTime date;
  final String timeSlot;
  final String courtType;
  final int durationHours;

  const CustomerBooking({
    required this.id,
    required this.court,
    required this.status,
    required this.date,
    required this.timeSlot,
    required this.courtType,
    required this.durationHours,
  });

  double get totalAmount => court.pricePerHour * durationHours;
}

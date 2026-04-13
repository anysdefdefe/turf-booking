import 'court_model.dart';

class BookingArgs {
  final Court court;
  final DateTime date;
  final String timeSlot;
  final String courtType;
  final int durationHours;

  BookingArgs({
    required this.court,
    required this.date,
    required this.timeSlot,
    required this.courtType,
    required this.durationHours,
  });
}

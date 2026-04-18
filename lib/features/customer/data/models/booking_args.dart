import 'court_model.dart';

class BookingArgs {
  final Court court;
  final DateTime date;
  final List<String> slots;
  final String courtType;

  BookingArgs({
    required this.court,
    required this.date,
    required this.slots,
    required this.courtType,
  });

  String get timeSlot => slots.isEmpty ? '' : slots.first;

  int get durationHours => slots.length;
}

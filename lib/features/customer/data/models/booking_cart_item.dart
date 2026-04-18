import 'court_model.dart';

class BookingCartItem {
  final String id;
  final Court court;
  final DateTime date;
  final List<String> slots;
  final DateTime createdAt;

  const BookingCartItem({
    required this.id,
    required this.court,
    required this.date,
    required this.slots,
    required this.createdAt,
  });

  int get durationHours => slots.length;

  double get totalAmount => court.pricePerHour * durationHours;

  String get sportsLabel => court.courtTypes.join(', ');
}

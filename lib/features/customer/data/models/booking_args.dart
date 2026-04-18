import 'booking_cart_item.dart';

class BookingArgs {
  final List<BookingCartItem> cartItems;

  const BookingArgs({required this.cartItems});

  int get totalSlots => cartItems.fold<int>(
    0,
    (sum, item) => sum + item.durationHours,
  );

  double get totalAmount => cartItems.fold<double>(
    0,
    (sum, item) => sum + item.totalAmount,
  );
}

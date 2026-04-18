import 'package:flutter/foundation.dart';

import '../models/booking_cart_item.dart';

class CustomerCartRepository {
  CustomerCartRepository._();

  static final CustomerCartRepository instance = CustomerCartRepository._();

  final ValueNotifier<List<BookingCartItem>> cartItemsNotifier =
      ValueNotifier<List<BookingCartItem>>(const []);

  List<BookingCartItem> getAllItems() =>
      List<BookingCartItem>.unmodifiable(cartItemsNotifier.value);

  int get itemCount => cartItemsNotifier.value.length;

  void addItem(BookingCartItem item) {
    final next = List<BookingCartItem>.from(cartItemsNotifier.value)
      ..insert(0, item);
    cartItemsNotifier.value = next;
  }

  void removeItem(String cartItemId) {
    final next = cartItemsNotifier.value
        .where((item) => item.id != cartItemId)
        .toList(growable: false);
    cartItemsNotifier.value = next;
  }

  void clear() {
    cartItemsNotifier.value = const [];
  }
}

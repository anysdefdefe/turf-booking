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

  bool containsEquivalent(BookingCartItem item) {
    return cartItemsNotifier.value.any(
      (existing) => _isSameSelection(existing, item),
    );
  }

  bool hasConflictForSelection({
    required String courtId,
    required DateTime date,
    required List<String> slots,
  }) {
    final normalizedSlots = List<String>.from(slots)..sort();
    return cartItemsNotifier.value.any((existing) {
      final sameCourt = existing.court.id == courtId;
      final sameDate =
          existing.date.year == date.year &&
          existing.date.month == date.month &&
          existing.date.day == date.day;
      final existingSlots = List<String>.from(existing.slots)..sort();
      final sameSlots = _sameOrderedValues(existingSlots, normalizedSlots);
      return sameCourt && sameDate && sameSlots;
    });
  }

  void addItem(BookingCartItem item) {
    if (containsEquivalent(item)) {
      return;
    }
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

  bool _isSameSelection(BookingCartItem a, BookingCartItem b) {
    final sameCourt = a.court.id == b.court.id;
    final sameDate =
        a.date.year == b.date.year &&
        a.date.month == b.date.month &&
        a.date.day == b.date.day;

    final aSlots = List<String>.from(a.slots)..sort();
    final bSlots = List<String>.from(b.slots)..sort();
    return sameCourt && sameDate && _sameOrderedValues(aSlots, bSlots);
  }

  bool _sameOrderedValues(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

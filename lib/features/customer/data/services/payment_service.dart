import '../models/booking_cart_item.dart';
import '../models/customer_booking.dart';
import '../models/payment_models.dart';
import '../repositories/customer_booking_repository.dart';
import '../repositories/customer_cart_repository.dart';
import 'payment_gateway.dart';

class PaymentService {
  PaymentService({
    required this.bookingRepository,
    required this.cartRepository,
    required this.dummyGateway,
    required this.stripeGateway,
  });

  final CustomerBookingRepository bookingRepository;
  final CustomerCartRepository cartRepository;
  final PaymentGateway dummyGateway;
  final PaymentGateway stripeGateway;

  Future<CheckoutResult> checkoutCart({
    required List<BookingCartItem> cartItems,
    PaymentMethod method = PaymentMethod.dummy,
  }) async {
    if (cartItems.isEmpty) {
      return const CheckoutResult(
        paymentResult: PaymentResult.failure('Cart is empty.'),
        successfulBookings: <CustomerBooking>[],
        failedItems: <BookingCartItem>[],
        bookingErrors: <String>[],
      );
    }

    final totalAmount = cartItems.fold<double>(
      0,
      (sum, item) => sum + item.totalAmount,
    );
    final paymentRequest = PaymentRequest(
      amount: totalAmount,
      currency: 'INR',
      description: 'Court booking checkout (${cartItems.length} item(s))',
    );

    final gateway = _gatewayFor(method);
    final payment = await gateway.processPayment(paymentRequest);
    if (!payment.isSuccess) {
      return CheckoutResult(
        paymentResult: payment,
        successfulBookings: const <CustomerBooking>[],
        failedItems: cartItems,
      );
    }

    final successfulBookings = <CustomerBooking>[];
    final failedItems = <BookingCartItem>[];
    final bookingErrors = <String>[];

    for (final item in cartItems) {
      final bookingId =
          'BK-${DateTime.now().microsecondsSinceEpoch.toString().substring(6)}';

      final booking = CustomerBooking(
        id: bookingId,
        court: item.court,
        status: BookingStatus.booked,
        date: item.date,
        slots: item.slots,
        courtType: item.court.courtTypes.isEmpty
            ? 'Court Booking'
            : item.court.courtTypes.first,
      );

      try {
        await bookingRepository.addBooking(booking);
        successfulBookings.add(booking);
      } catch (e) {
        failedItems.add(item);
        bookingErrors.add(e.toString());
      }
    }

    if (successfulBookings.isNotEmpty) {
      final successfulCartIds = successfulBookings
          .map((booking) => _findCartItemId(booking, cartItems))
          .whereType<String>()
          .toSet();

      for (final cartId in successfulCartIds) {
        cartRepository.removeItem(cartId);
      }
    }

    if (successfulBookings.isEmpty && failedItems.isNotEmpty) {
      final reason = bookingErrors.isEmpty
          ? 'Unable to create booking records in backend.'
          : bookingErrors.first;

      return CheckoutResult(
        paymentResult: PaymentResult.failure(
          'Payment simulation passed, but booking creation failed: $reason',
        ),
        successfulBookings: successfulBookings,
        failedItems: failedItems,
        bookingErrors: bookingErrors,
      );
    }

    return CheckoutResult(
      paymentResult: payment,
      successfulBookings: successfulBookings,
      failedItems: failedItems,
      bookingErrors: bookingErrors,
    );
  }

  PaymentGateway _gatewayFor(PaymentMethod method) {
    if (method == PaymentMethod.stripe) {
      return stripeGateway;
    }
    return dummyGateway;
  }

  String? _findCartItemId(
    CustomerBooking booking,
    List<BookingCartItem> cartItems,
  ) {
    for (final item in cartItems) {
      final isSameCourt = item.court.id == booking.court.id;
      final isSameDate =
          item.date.year == booking.date.year &&
          item.date.month == booking.date.month &&
          item.date.day == booking.date.day;
      final isSameSlots =
          item.slots.length == booking.slots.length &&
          item.slots.every((slot) => booking.slots.contains(slot));

      if (isSameCourt && isSameDate && isSameSlots) {
        return item.id;
      }
    }
    return null;
  }
}

import 'booking_cart_item.dart';
import 'customer_booking.dart';

enum PaymentMethod { dummy, stripe }

enum PaymentGatewayType { dummy, stripe }

class PaymentRequest {
  final double amount;
  final String currency;
  final String description;

  const PaymentRequest({
    required this.amount,
    required this.currency,
    required this.description,
  });
}

class PaymentReceipt {
  final String transactionId;
  final PaymentGatewayType gateway;
  final double amount;
  final String currency;
  final DateTime paidAt;

  const PaymentReceipt({
    required this.transactionId,
    required this.gateway,
    required this.amount,
    required this.currency,
    required this.paidAt,
  });
}

class PaymentResult {
  final bool isSuccess;
  final PaymentReceipt? receipt;
  final String? errorMessage;

  const PaymentResult._({
    required this.isSuccess,
    this.receipt,
    this.errorMessage,
  });

  const PaymentResult.success(PaymentReceipt receipt)
    : this._(isSuccess: true, receipt: receipt);

  const PaymentResult.failure(String message)
    : this._(isSuccess: false, errorMessage: message);
}

class CheckoutResult {
  final PaymentResult paymentResult;
  final List<CustomerBooking> successfulBookings;
  final List<BookingCartItem> failedItems;
  final List<String> bookingErrors;

  const CheckoutResult({
    required this.paymentResult,
    required this.successfulBookings,
    required this.failedItems,
    this.bookingErrors = const <String>[],
  });

  bool get hasAnySuccess => successfulBookings.isNotEmpty;

  bool get isFullySuccessful =>
      paymentResult.isSuccess &&
      failedItems.isEmpty &&
      successfulBookings.isNotEmpty;
}

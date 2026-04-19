import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/booking_args.dart';
import '../data/models/payment_models.dart';
import '../data/repositories/customer_booking_repository.dart';
import '../data/repositories/customer_cart_repository.dart';
import '../data/services/payment_gateway.dart';
import '../data/services/payment_service.dart';

final dummyPaymentGatewayProvider = Provider<PaymentGateway>((ref) {
  return DummyPaymentGateway();
});

final stripePaymentGatewayProvider = Provider<PaymentGateway>((ref) {
  return StripePaymentGateway();
});

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(
    bookingRepository: CustomerBookingRepository.instance,
    cartRepository: CustomerCartRepository.instance,
    dummyGateway: ref.read(dummyPaymentGatewayProvider),
    stripeGateway: ref.read(stripePaymentGatewayProvider),
  );
});

final paymentControllerProvider =
    AsyncNotifierProvider<PaymentController, CheckoutResult?>(
      PaymentController.new,
    );

class PaymentController extends AsyncNotifier<CheckoutResult?> {
  @override
  Future<CheckoutResult?> build() async {
    return null;
  }

  Future<CheckoutResult> checkout(
    BookingArgs args, {
    PaymentMethod method = PaymentMethod.dummy,
  }) async {
    state = const AsyncValue.loading();

    final result = await ref
        .read(paymentServiceProvider)
        .checkoutCart(cartItems: args.cartItems, method: method);

    state = AsyncValue.data(result);
    return result;
  }
}

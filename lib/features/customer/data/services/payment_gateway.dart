import '../models/payment_models.dart';

abstract class PaymentGateway {
  PaymentGatewayType get gatewayType;

  Future<PaymentResult> processPayment(PaymentRequest request);
}

class DummyPaymentGateway implements PaymentGateway {
  @override
  PaymentGatewayType get gatewayType => PaymentGatewayType.dummy;

  @override
  Future<PaymentResult> processPayment(PaymentRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final txnId = 'DUMMY-${DateTime.now().millisecondsSinceEpoch}';

    return PaymentResult.success(
      PaymentReceipt(
        transactionId: txnId,
        gateway: gatewayType,
        amount: request.amount,
        currency: request.currency,
        paidAt: DateTime.now(),
      ),
    );
  }
}

class StripePaymentGateway implements PaymentGateway {
  @override
  PaymentGatewayType get gatewayType => PaymentGatewayType.stripe;

  @override
  Future<PaymentResult> processPayment(PaymentRequest request) async {
    return const PaymentResult.failure(
      'Stripe payment is not configured yet. Please use dummy payment for now.',
    );
  }
}

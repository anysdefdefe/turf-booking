import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/constants/app_constants.dart';
import '../../../app/theme/app_colors.dart';
import '../data/models/booking_args.dart';
import '../data/models/customer_booking.dart';
import '../data/repositories/customer_booking_repository.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final BookingArgs args;

  const BookingConfirmationScreen({super.key, required this.args});

  void _onProceedToPay(BuildContext context) {
    _createBooking(context, BookingStatus.booked);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment Successful! Booking Confirmed.')),
    );
    context.go(AppConstants.routeMyBookings);
  }

  void _onPayLater(BuildContext context) {
    _createBooking(context, BookingStatus.unpaid);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking saved. Please pay later to confirm your slots!'),
      ),
    );
    context.go(AppConstants.routeMyBookings);
  }

  void _onCancel(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    }
  }

  void _createBooking(BuildContext context, BookingStatus status) {
    final newId = 'BK-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final newBooking = CustomerBooking(
      id: newId,
      court: args.court,
      status: status,
      date: args.date,
      slots: args.slots,
      courtType: args.courtType,
    );
    CustomerBookingRepository.instance.addBooking(newBooking);
  }

  @override
  Widget build(BuildContext context) {
    final double totalAmount = args.court.pricePerHour * args.durationHours;
    final formattedDate = DateFormat('EEEE, MMM d, yyyy').format(args.date);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => _onCancel(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Turf Card Info
              _buildCourtCard(),
              const SizedBox(height: 24),

              // Booking Details Section
              const Text(
                'Booking Summary',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryRow(Icons.calendar_today_rounded, 'Date', formattedDate),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: AppColors.divider, height: 1),
                    ),
                    _buildSummaryRow(
                      Icons.access_time_rounded,
                      'Time Slot',
                      args.slots.join(', '),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: AppColors.divider, height: 1),
                    ),
                    _buildSummaryRow(Icons.sports_tennis_rounded, 'Sport', args.courtType),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: AppColors.divider, height: 1),
                    ),
                    _buildSummaryRow(
                      Icons.timer_rounded,
                      'Duration',
                      '${args.durationHours} hr${args.durationHours > 1 ? 's' : ''}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Billing Details Section
              const Text(
                'Payment Details',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    _buildPriceRow(
                      'Price (1 hr)',
                      '₹${args.court.pricePerHour.toInt()}',
                    ),
                    const SizedBox(height: 10),
                    _buildPriceRow(
                      'Slots',
                      'x${args.durationHours}',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: AppColors.divider, height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Grand Total',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '₹${totalAmount.toInt()}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _onCancel(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _onPayLater(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        foregroundColor: AppColors.primary,
                      ),
                      child: const Text(
                        'Pay Later',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _onProceedToPay(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Proceed to Pay',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourtCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Image.network(
            args.court.imageUrl,
            height: 140,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 140,
              width: double.infinity,
              color: AppColors.divider,
              child: const Icon(Icons.sports_tennis_rounded,
                  size: 40, color: AppColors.textMuted),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        args.court.name,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        args.court.stadiumName,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${args.court.place}, ${args.court.city}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.verified_rounded,
                      color: AppColors.primary, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

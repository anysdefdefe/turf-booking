import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../data/models/customer_booking.dart';

class CourtCompactCard extends StatelessWidget {
  final CustomerBooking booking;
  final VoidCallback onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onPayNow;

  const CourtCompactCard({
    super.key,
    required this.booking,
    required this.onTap,
    this.onCancel,
    this.onPayNow,
  });

  @override
  Widget build(BuildContext context) {
    final court = booking.court;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    court.name,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '₹${booking.totalAmount.toInt()}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              court.stadiumName,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${court.place}, ${court.city}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${booking.courtType} • ${booking.durationHours} hr${booking.durationHours > 1 ? 's' : ''}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: booking.slots
                  .map(
                    (slot) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        slot,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _StatusChip(status: booking.status),
                const Spacer(),
                Text(
                  _formatBookingDate(booking.date),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Money not refundable',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            if (onCancel != null || onPayNow != null) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onCancel != null)
                    OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  if (onCancel != null && onPayNow != null)
                    const SizedBox(width: 8),
                  if (onPayNow != null)
                    FilledButton.icon(
                      onPressed: onPayNow,
                      icon: const Icon(Icons.payment_rounded, size: 16),
                      label: const Text('Pay Now'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatBookingDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final firstSlot = booking.slots.isEmpty ? '-' : booking.slots.first;
    return '${d.day} ${months[d.month - 1]} • $firstSlot';
  }
}

class _StatusChip extends StatelessWidget {
  final BookingStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isCancelled = status == BookingStatus.cancelled;
    final isUnpaid = status == BookingStatus.unpaid;

    Color bgColor = AppColors.surface;
    Color borderColor = AppColors.primary;
    String label = 'Booked';

    if (isCancelled) {
      bgColor = AppColors.surface;
      borderColor = Colors.red.shade200;
      label = 'Cancelled';
    } else if (isUnpaid) {
      bgColor = Colors.orange.shade50;
      borderColor = Colors.orange;
      label = 'Unpaid';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

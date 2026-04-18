import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/models/customer_booking.dart';
import '../data/repositories/customer_booking_repository.dart';
import '../widgets/court_compact_card.dart';
import '../widgets/customer_floating_nav_bar.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final CustomerBookingRepository _repo = CustomerBookingRepository.instance;
  int _selectedFilterIndex = 0;

  List<CustomerBooking> get _bookings {
    final all = _repo.getAllBookings();
    if (_selectedFilterIndex == 1) {
      return all
          .where((b) => b.status == BookingStatus.booked && !b.isPast)
          .toList();
    }
    if (_selectedFilterIndex == 2) {
      return all.where((b) => b.status == BookingStatus.unpaid).toList();
    }
    if (_selectedFilterIndex == 3) {
      return all
          .where((b) => b.status == BookingStatus.booked && b.isPast)
          .toList();
    }
    if (_selectedFilterIndex == 4) {
      return all.where((b) => b.status == BookingStatus.cancelled).toList();
    }
    return all;
  }

  Future<void> _onCancelBooking(CustomerBooking booking) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: const Text(
          'Money not refundable. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep booking'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );

    if (ok != true) {
      return;
    }

    setState(() {
      _repo.cancelBooking(booking.id);
    });
  }

  void _onPayNow(CustomerBooking booking) {
    setState(() {
      _repo.updateBookingStatus(booking.id, BookingStatus.booked);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment Successful! Booking Confirmed.')),
    );
  }

  void _openReceiptPlaceholder(CustomerBooking booking) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Digital receipt'),
        content: Text(
          'Receipt for booking ${booking.id} will be available soon.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _onNavTap(int index) {
    if (index == 1) return;
    if (index == 0) {
      context.go('/customer/home');
      return;
    }
    if (index == 2) {
      context.go('/customer/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: CustomerFloatingNavBar(
        selectedIndex: 1,
        onTap: _onNavTap,
      ),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'My Bookings',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterRow(),
          Expanded(
            child: _bookings.isEmpty
                ? const EmptyState(
                    title: 'No bookings yet',
                    subtitle: 'Your bookings will appear here',
                    icon: Icons.event_note_rounded,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: _bookings.length,
                    itemBuilder: (context, index) {
                      final booking = _bookings[index];
                      return CourtCompactCard(
                        booking: booking,
                        onTap: () => _openReceiptPlaceholder(booking),
                        onCancel: booking.canCancel
                            ? () => _onCancelBooking(booking)
                            : null,
                        onPayNow: booking.status == BookingStatus.unpaid
                            ? () => _onPayNow(booking)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    const labels = ['All', 'Upcoming', 'Unpaid', 'Past', 'Cancelled'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = _selectedFilterIndex == index;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == labels.length - 1 ? 0 : 8,
              ),
              child: InkWell(
                onTap: () => setState(() => _selectedFilterIndex = index),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.divider,
                      width: selected ? 1.4 : 1,
                    ),
                  ),
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

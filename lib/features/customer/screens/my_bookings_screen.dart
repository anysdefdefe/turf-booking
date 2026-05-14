import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/models/customer_booking.dart';
import '../data/repositories/customer_booking_repository.dart';
import '../providers/customer_bookings_controller.dart';
import '../widgets/court_compact_card.dart';
import '../widgets/customer_bottom_nav_bar.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key, this.toastMessage});

  final String? toastMessage;

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  final CustomerBookingRepository _repo = CustomerBookingRepository.instance;
  int _selectedFilterIndex = 0;
  bool _hasShownToast = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(customerBookingsControllerProvider.future),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasShownToast) {
        return;
      }
      final text = widget.toastMessage;
      if (text == null || text.trim().isEmpty) {
        return;
      }
      _hasShownToast = true;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    });
  }

  List<CustomerBooking> _bookingsForFilter(List<CustomerBooking> all) {
    if (_selectedFilterIndex == 1) {
      return all
          .where((b) => b.status == BookingStatus.booked && !b.isPast)
          .toList();
    }
    if (_selectedFilterIndex == 2) {
      return all
          .where((b) => b.status == BookingStatus.booked && b.isPast)
          .toList();
    }
    if (_selectedFilterIndex == 3) {
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
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Keep booking',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Cancel booking',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (ok != true) {
      return;
    }

    await ref
        .read(customerBookingsControllerProvider.notifier)
        .cancelBooking(booking);

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Booking cancelled.')));
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
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Close',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _onNavTap(int index) {
    if (index == 2) return;
    if (index == 0) {
      context.go('/customer/home');
      return;
    }
    if (index == 1) {
      context.go('/customer/cart');
      return;
    }
    if (index == 3) {
      context.go('/customer/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(customerBookingsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: CustomerBottomNavBar(
        selectedIndex: 2,
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
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          if (bookingState.isLoading)
            const LinearProgressIndicator(minHeight: 2),
          _buildFilterRow(),
          ValueListenableBuilder<List<CustomerBooking>>(
            valueListenable: _repo.bookingsNotifier,
            builder: (context, allBookings, _) {
              final ordered = [...allBookings]
                ..sort((a, b) => b.startDateTime.compareTo(a.startDateTime));
              final bookings = _bookingsForFilter(ordered);

              return Expanded(
                child: bookings.isEmpty
                    ? const EmptyState(
                        title: 'No bookings yet',
                        subtitle: 'Your bookings will appear here',
                        icon: Icons.event_note_rounded,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 24),
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          final booking = bookings[index];
                          return CourtCompactCard(
                            booking: booking,
                            onTap: () => _openReceiptPlaceholder(booking),
                            onCancel: booking.canCancel
                                ? () => _onCancelBooking(booking)
                                : null,
                          );
                        },
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    const labels = ['All', 'Upcoming', 'Past', 'Cancelled'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(labels.length, (index) {
          final selected = _selectedFilterIndex == index;
          return InkWell(
            onTap: () => setState(() => _selectedFilterIndex = index),
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(999),
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
          );
        }),
      ),
    );
  }
}

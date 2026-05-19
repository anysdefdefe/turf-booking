import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Keep booking',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,

              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Cancel booking',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
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
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Close',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
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
    final bookingState = ref.watch(customerBookingsControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      bottomNavigationBar: CustomerBottomNavBar(
        selectedIndex: 1,
        onTap: _onNavTap,
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'My Bookings',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: Column(
        children: [
          if (bookingState.isLoading)
            const LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: Colors.transparent,
            ),
          _buildFilterRow(),
          Expanded(
            child: ValueListenableBuilder<List<CustomerBooking>>(
              valueListenable: _repo.bookingsNotifier,
              builder: (context, allBookings, _) {
                final ordered = [...allBookings]
                  ..sort((a, b) => b.startDateTime.compareTo(a.startDateTime));
                final bookings = _bookingsForFilter(ordered);

                if (bookings.isEmpty) {
                  return const EmptyState(
                    title: 'No bookings yet',
                    subtitle: 'Your bookings will appear here',
                    icon: Icons.event_note_rounded,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    top: 12,
                    bottom: 24,
                    left: 16,
                    right: 16,
                  ),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CourtCompactCard(
                        booking: booking,
                        onTap: () => _openReceiptPlaceholder(booking),
                        onCancel: booking.canCancel
                            ? () => _onCancelBooking(booking)
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    const labels = ['All', 'Upcoming', 'Past', 'Cancelled'];
    const icons = [
      Icons.inbox_rounded,
      Icons.calendar_month_rounded,
      Icons.history_rounded,
      Icons.close_rounded,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = _selectedFilterIndex == index;
          return Padding(
            padding: EdgeInsets.only(right: index < labels.length - 1 ? 8 : 0),
            child: InkWell(
              onTap: () => setState(() => _selectedFilterIndex = index),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.5),
                    width: selected ? 0 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icons[index],
                      size: 16,
                      color: selected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      labels[index],
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        letterSpacing: 0.2,
                        color: selected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

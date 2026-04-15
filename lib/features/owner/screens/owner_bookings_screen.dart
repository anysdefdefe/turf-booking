import 'package:flutter/material.dart';
import 'package:turf_booking/app/theme/app_colors.dart';
import 'package:turf_booking/app/constants/app_constants.dart';
import '../widgets/owner_bottom_nav_bar.dart';

// ── MOCK DATA ─────────────────────────────────────────────────────────────────

class BookingEntry {
  final String id;
  final String customerName;
  final String courtName;
  final String stadiumName;
  final String date;
  final String startTime;
  final String endTime;
  final String status;
  final double amount;

  const BookingEntry({
    required this.id,
    required this.customerName,
    required this.courtName,
    required this.stadiumName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.amount,
  });
}

const List<BookingEntry> _mockBookings = [
  BookingEntry(
    id: '1',
    customerName: 'Arjun Mehta',
    courtName: 'Court A',
    stadiumName: 'Green Arena',
    date: 'Today',
    startTime: '6:00 AM',
    endTime: '7:00 AM',
    status: 'confirmed',
    amount: 500,
  ),
  BookingEntry(
    id: '2',
    customerName: 'Priya Sharma',
    courtName: 'Court B',
    stadiumName: 'Turf Zone',
    date: 'Today',
    startTime: '7:00 AM',
    endTime: '8:00 AM',
    status: 'pending',
    amount: 600,
  ),
  BookingEntry(
    id: '3',
    customerName: 'Rahul Nair',
    courtName: 'Court A',
    stadiumName: 'Green Arena',
    date: 'Today',
    startTime: '8:00 AM',
    endTime: '9:00 AM',
    status: 'confirmed',
    amount: 500,
  ),
  BookingEntry(
    id: '4',
    customerName: 'Sneha Kapoor',
    courtName: 'Court C',
    stadiumName: 'PlayField Hub',
    date: 'Tomorrow',
    startTime: '10:00 AM',
    endTime: '11:00 AM',
    status: 'pending',
    amount: 450,
  ),
  BookingEntry(
    id: '5',
    customerName: 'Vikram Iyer',
    courtName: 'Court A',
    stadiumName: 'Turf Zone',
    date: 'Tomorrow',
    startTime: '4:00 PM',
    endTime: '5:00 PM',
    status: 'cancelled',
    amount: 600,
  ),
  BookingEntry(
    id: '6',
    customerName: 'Meena Rao',
    courtName: 'Court B',
    stadiumName: 'Green Arena',
    date: 'Yesterday',
    startTime: '6:00 AM',
    endTime: '7:00 AM',
    status: 'confirmed',
    amount: 500,
  ),
];

// ── SCREEN ────────────────────────────────────────────────────────────────────

class OwnerBookingsScreen extends StatefulWidget {
  const OwnerBookingsScreen({super.key});

  @override
  State<OwnerBookingsScreen> createState() => _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends State<OwnerBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  final List<String> _tabs = ['All', 'Pending', 'Confirmed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<BookingEntry> get _filteredBookings {
    final tabIndex = _tabController.index;
    List<BookingEntry> result = _mockBookings;

    if (tabIndex == 1) {
      result = result.where((b) => b.status == 'pending').toList();
    }
    if (tabIndex == 2) {
      result = result.where((b) => b.status == 'confirmed').toList();
    }
    if (tabIndex == 3) {
      result = result.where((b) => b.status == 'cancelled').toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where(
            (b) =>
                b.customerName.toLowerCase().contains(q) ||
                b.courtName.toLowerCase().contains(q) ||
                b.stadiumName.toLowerCase().contains(q) ||
                b.date.toLowerCase().contains(q),
          )
          .toList();
    }

    return result;
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterSheet(),
    );
  }

  void _showStatusDialog(BookingEntry booking) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
        ),
        title: const Text(
          'Update Status',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        content: Text(
          'Change status for ${booking.customerName}\'s booking?',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackbar('Booking approved (mock)');
            },
            child: const Text(
              'Approve',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackbar('Booking rejected (mock)');
            },
            child: const Text(
              'Reject',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const OwnerBottomNavBar(selectedIndex: 2),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Bookings',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) => setState(() {}),
          labelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
          ),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Column(
        children: [
          // ── SEARCH + FILTER ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search by name, court, stadium...',
                        hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── BOOKING LIST ─────────────────────────────────────────
          Expanded(
            child: _filteredBookings.isEmpty
                ? _buildEmpty()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _filteredBookings.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final booking = _filteredBookings[index];
                      return _BookingCard(
                        booking: booking,
                        onStatusTap: () => _showStatusDialog(booking),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_online_outlined,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          const Text(
            'No bookings found',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search or filter',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── BOOKING CARD ──────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final BookingEntry booking;
  final VoidCallback onStatusTap;

  const _BookingCard({required this.booking, required this.onStatusTap});

  Color get _statusColor {
    switch (booking.status) {
      case 'confirmed':
        return AppColors.primary;
      case 'pending':
        return const Color(0xFFE6A800);
      case 'cancelled':
        return Colors.redAccent;
      default:
        return AppColors.textMuted;
    }
  }

  Color get _statusBg {
    switch (booking.status) {
      case 'confirmed':
        return AppColors.badgeBg;
      case 'pending':
        return const Color(0xFFFFF8E1);
      case 'cancelled':
        return const Color(0xFFFFEBEB);
      default:
        return AppColors.chipUnselected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── TOP ROW ────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.badgeBg,
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.customerName,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${booking.courtName} — ${booking.stadiumName}',
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  booking.status[0].toUpperCase() + booking.status.substring(1),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 10),

          // ── BOTTOM ROW ─────────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 13,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                booking.date,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.access_time_rounded,
                size: 13,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                '${booking.startTime} – ${booking.endTime}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '₹${booking.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          // ── STATUS ACTIONS (only for pending) ──────────────────
          if (booking.status == 'pending') ...[
            const SizedBox(height: 10),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onStatusTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.badgeBg,
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusS,
                        ),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: const Center(
                        child: Text(
                          'Approve',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onStatusTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEB),
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusS,
                        ),
                        border: Border.all(color: Colors.redAccent),
                      ),
                      child: const Center(
                        child: Text(
                          'Reject',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── FILTER SHEET ──────────────────────────────────────────────────────────────

class _FilterSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Bookings',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Date',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Today', 'Tomorrow', 'Yesterday', 'This Week']
                  .map(
                    (label) => GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.chipUnselected,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Court',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Court A', 'Court B', 'Court C']
                  .map(
                    (label) => GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.chipUnselected,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

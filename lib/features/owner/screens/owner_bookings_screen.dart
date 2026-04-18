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
    status: 'confirmed',
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
    status: 'confirmed',
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
  String? _dateFilter;
  String? _courtFilter;

  final List<String> _tabs = ['All', 'Confirmed', 'Cancelled'];

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
      result = result.where((b) => b.status == 'confirmed').toList();
    }
    if (tabIndex == 2) {
      result = result.where((b) => b.status == 'cancelled').toList();
    }

    if (_dateFilter != null) {
      result = result.where((b) => b.date == _dateFilter).toList();
    }
    if (_courtFilter != null) {
      result = result.where((b) => b.courtName == _courtFilter).toList();
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

  bool get _hasActiveFilters => _dateFilter != null || _courtFilter != null;

  // ── REVENUE SUMMARY ────────────────────────────────────────────
  double get _todayRevenue => _mockBookings
      .where((b) => b.date == 'Today' && b.status == 'confirmed')
      .fold(0, (sum, b) => sum + b.amount);

  int get _todayBookings =>
      _mockBookings.where((b) => b.date == 'Today').length;

  void _showFilterSheet() async {
    final result = await showModalBottomSheet<Map<String, String?>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _FilterSheet(selectedDate: _dateFilter, selectedCourt: _courtFilter),
    );
    if (result != null) {
      setState(() {
        _dateFilter = result['date'];
        _courtFilter = result['court'];
      });
    }
  }

  void _showBookingDetail(BookingEntry booking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _BookingDetailSheet(booking: booking),
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
        actions: [
          if (_hasActiveFilters)
            TextButton(
              onPressed: () => setState(() {
                _dateFilter = null;
                _courtFilter = null;
              }),
              child: const Text(
                'Clear',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
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
          // ── TODAY SUMMARY BAR ────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.badgeBg,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                _SummaryItem(
                  label: "Today's Revenue",
                  value: '₹${_todayRevenue.toStringAsFixed(0)}',
                  icon: Icons.currency_rupee_rounded,
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: AppColors.primary.withValues(alpha: 0.2),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                _SummaryItem(
                  label: "Today's Bookings",
                  value: '$_todayBookings',
                  icon: Icons.event_available_rounded,
                ),
              ],
            ),
          ),

          // ── SEARCH + FILTER ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                  child: Stack(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: _hasActiveFilters
                              ? AppColors.badgeBg
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusM,
                          ),
                          border: Border.all(
                            color: _hasActiveFilters
                                ? AppColors.primary
                                : AppColors.divider,
                          ),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: _hasActiveFilters
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                      if (_hasActiveFilters)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── ACTIVE FILTER CHIPS ──────────────────────────────────
          if (_hasActiveFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  if (_dateFilter != null)
                    _ActiveFilterChip(
                      label: _dateFilter!,
                      onRemove: () => setState(() => _dateFilter = null),
                    ),
                  if (_dateFilter != null && _courtFilter != null)
                    const SizedBox(width: 8),
                  if (_courtFilter != null)
                    _ActiveFilterChip(
                      label: _courtFilter!,
                      onRemove: () => setState(() => _courtFilter = null),
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
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final booking = _filteredBookings[index];
                      return _BookingCard(
                        booking: booking,
                        onTap: () => _showBookingDetail(booking),
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

// ── SUMMARY ITEM ──────────────────────────────────────────────────────────────

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── ACTIVE FILTER CHIP ────────────────────────────────────────────────────────

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ActiveFilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.badgeBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ── BOOKING CARD ──────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final BookingEntry booking;
  final VoidCallback onTap;

  const _BookingCard({required this.booking, required this.onTap});

  Color get _statusColor {
    switch (booking.status) {
      case 'confirmed':
        return AppColors.primary;
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
      case 'cancelled':
        return const Color(0xFFFFEBEB);
      default:
        return AppColors.chipUnselected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.status[0].toUpperCase() +
                        booking.status.substring(1),
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
          ],
        ),
      ),
    );
  }
}

// ── BOOKING DETAIL SHEET ──────────────────────────────────────────────────────

class _BookingDetailSheet extends StatelessWidget {
  final BookingEntry booking;

  const _BookingDetailSheet({required this.booking});

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
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Booking Details',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.person_outline_rounded,
              label: 'Customer',
              value: booking.customerName,
            ),
            _DetailRow(
              icon: Icons.stadium_rounded,
              label: 'Stadium',
              value: booking.stadiumName,
            ),
            _DetailRow(
              icon: Icons.sports_soccer_rounded,
              label: 'Court',
              value: booking.courtName,
            ),
            _DetailRow(
              icon: Icons.calendar_today_rounded,
              label: 'Date',
              value: booking.date,
            ),
            _DetailRow(
              icon: Icons.access_time_rounded,
              label: 'Time',
              value: '${booking.startTime} – ${booking.endTime}',
            ),
            _DetailRow(
              icon: Icons.currency_rupee_rounded,
              label: 'Amount',
              value: '₹${booking.amount.toStringAsFixed(0)}',
            ),
            _DetailRow(
              icon: Icons.check_circle_outline_rounded,
              label: 'Status',
              value:
                  booking.status[0].toUpperCase() + booking.status.substring(1),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── FILTER SHEET ──────────────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final String? selectedDate;
  final String? selectedCourt;

  const _FilterSheet({this.selectedDate, this.selectedCourt});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _date;
  String? _court;

  @override
  void initState() {
    super.initState();
    _date = widget.selectedDate;
    _court = widget.selectedCourt;
  }

  Widget _chip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.badgeBg : AppColors.chipUnselected,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                if (_date != null || _court != null)
                  GestureDetector(
                    onTap: () => setState(() {
                      _date = null;
                      _court = null;
                    }),
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
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
              runSpacing: 8,
              children: ['Today', 'Tomorrow', 'Yesterday', 'This Week']
                  .map(
                    (label) => _chip(
                      label,
                      _date == label,
                      () =>
                          setState(() => _date = _date == label ? null : label),
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
              runSpacing: 8,
              children: ['Court A', 'Court B', 'Court C']
                  .map(
                    (label) => _chip(
                      label,
                      _court == label,
                      () => setState(
                        () => _court = _court == label ? null : label,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () =>
                    Navigator.pop(context, {'date': _date, 'court': _court}),
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

// owner_bookings_screen.dart

import 'package:flutter/material.dart';
import 'package:turf_booking/app/theme/app_colors.dart';
import 'package:turf_booking/app/constants/app_constants.dart';
import '../widgets/owner_bottom_nav_bar.dart';

// ── MODEL ─────────────────────────────────────────────────────────────────────

class BookingEntry {
  final String id;
  final String customerName;
  final String courtName;
  final String stadiumName;
  final String date;
  final String startTime;
  final String endTime;
  final String status; // 'confirmed' | 'cancelled'
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

// ── MOCK DATA ─────────────────────────────────────────────────────────────────
// All bookings are auto-confirmed on slot selection. No pending state exists.

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

  // Tabs: 0 = All, 1 = Cancelled
  final List<String> _tabs = ['All', 'Cancelled'];

  String _searchQuery = '';
  String? _dateFilter;
  String? _courtFilter;

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

  // ── DERIVED DATA ────────────────────────────────────────────────────────────

  List<BookingEntry> get _filteredBookings {
    List<BookingEntry> result = List.of(_mockBookings);

    if (_tabController.index == 1) {
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

  double get _todayRevenue => _mockBookings
      .where((b) => b.date == 'Today' && b.status == 'confirmed')
      .fold(0.0, (sum, b) => sum + b.amount);

  int get _todayBookings =>
      _mockBookings.where((b) => b.date == 'Today').length;

  /// Groups every booking by courtName → { count, revenue, stadiumName }.
  Map<String, Map<String, dynamic>> get _courtStats {
    final Map<String, Map<String, dynamic>> stats = {};
    for (final b in _mockBookings) {
      stats.putIfAbsent(
        b.courtName,
        () => {'count': 0, 'revenue': 0.0, 'stadiumName': b.stadiumName},
      );
      stats[b.courtName]!['count'] = (stats[b.courtName]!['count'] as int) + 1;
      stats[b.courtName]!['revenue'] =
          (stats[b.courtName]!['revenue'] as double) + b.amount;
    }
    return stats;
  }

  // ── ACTIONS ─────────────────────────────────────────────────────────────────

  void _showFilterSheet() async {
    final result = await showModalBottomSheet<Map<String, String?>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _FilterSheet(selectedDate: _dateFilter, selectedCourt: _courtFilter),
    );
    if (result != null) {
      setState(() {
        _dateFilter = result['date'];
        _courtFilter = result['court'];
      });
    }
  }

  void _clearFilters() => setState(() {
    _dateFilter = null;
    _courtFilter = null;
  });

  // ── BUILD ────────────────────────────────────────────────────────────────────

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
              onPressed: _clearFilters,
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
          onTap: (_) => setState(() {}),
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
          _buildSummaryStrip(),
          _buildSearchRow(),
          if (_hasActiveFilters) _buildActiveChips(),
          _CourtBreakdown(courtStats: _courtStats),
          const SizedBox(height: 4),
          Expanded(
            child: _filteredBookings.isEmpty
                ? _buildEmpty()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: _filteredBookings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _BookingCard(booking: _filteredBookings[i]),
                  ),
          ),
        ],
      ),
    );
  }

  // ── SUB-BUILDERS ─────────────────────────────────────────────────────────────

  Widget _buildSummaryStrip() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.badgeBg,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
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
    );
  }

  Widget _buildSearchRow() {
    return Padding(
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
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
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
    );
  }

  Widget _buildActiveChips() {
    return Padding(
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

// ── COURT BREAKDOWN ───────────────────────────────────────────────────────────

class _CourtBreakdown extends StatefulWidget {
  final Map<String, Map<String, dynamic>> courtStats;

  const _CourtBreakdown({required this.courtStats});

  @override
  State<_CourtBreakdown> createState() => _CourtBreakdownState();
}

class _CourtBreakdownState extends State<_CourtBreakdown> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── HEADER ──────────────────────────────────────────
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bar_chart_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Court Breakdown',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _expanded ? 'Hide' : 'Show',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── ROWS (visible only when expanded) ───────────────
            if (_expanded) ...[
              const Divider(color: AppColors.divider, height: 1),
              ...widget.courtStats.entries.map((entry) {
                final court = entry.key;
                final stadium = entry.value['stadiumName'] as String;
                final count = entry.value['count'] as int;
                final revenue = entry.value['revenue'] as double;

                return Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.divider),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              court,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              stadium,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatPill(
                        label: '$count booking${count == 1 ? '' : 's'}',
                        isAccent: true,
                      ),
                      const SizedBox(width: 8),
                      _StatPill(
                        label: '₹${revenue.toStringAsFixed(0)}',
                        isAccent: false,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final bool isAccent;

  const _StatPill({required this.label, required this.isAccent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAccent ? AppColors.badgeBg : AppColors.chipUnselected,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAccent ? AppColors.primary : AppColors.divider,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isAccent ? AppColors.primary : AppColors.textSecondary,
        ),
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

  const _BookingCard({required this.booking});

  bool get _isCancelled => booking.status == 'cancelled';

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _isCancelled
        ? Colors.redAccent
        : AppColors.primary;
    final Color statusBg = _isCancelled
        ? const Color(0xFFFFEBEB)
        : AppColors.badgeBg;

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
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  booking.status[0].toUpperCase() + booking.status.substring(1),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
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
                    (l) => _chip(
                      l,
                      _date == l,
                      () => setState(() => _date = _date == l ? null : l),
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
                    (l) => _chip(
                      l,
                      _court == l,
                      () => setState(() => _court = _court == l ? null : l),
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

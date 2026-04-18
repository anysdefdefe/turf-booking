import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf_booking/app/constants/app_constants.dart';
import 'package:turf_booking/app/theme/app_colors.dart';
import '../data/owner_dummy_data.dart';
import '../widgets/owner_bottom_nav_bar.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final owner = dummyOwner;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const OwnerBottomNavBar(selectedIndex: 0),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              // authProvider in main.dart will automatically redirect to LoginScreen
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!owner.isApproved) const _PendingApprovalBanner(),

            const SizedBox(height: 8),

            // ── WELCOME ──────────────────────────────────────────────
            Text(
              '${owner.name}, good to see you!',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Here\'s your overview for today',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 24),

            // ── STAT CARDS ───────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Stadiums',
                    value: '2',
                    icon: Icons.stadium_rounded,
                    isLocked: !owner.isApproved,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Bookings',
                    value: '14',
                    icon: Icons.calendar_today_rounded,
                    isLocked: !owner.isApproved,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Revenue',
                    value: '₹4,200',
                    icon: Icons.currency_rupee_rounded,
                    isLocked: !owner.isApproved,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── TODAY'S BOOKINGS ─────────────────────────────────────
            const Text(
              "Today's Bookings",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),

            if (!owner.isApproved)
              const _LockedCard()
            else
              Column(
                children: [
                  _BookingItem(
                    customerName: 'Arjun Mehta',
                    courtName: 'Court A — Green Arena',
                    time: '9:00 AM – 10:00 AM',
                    status: 'confirmed',
                  ),
                  const SizedBox(height: 10),
                  _BookingItem(
                    customerName: 'Priya Sharma',
                    courtName: 'Court B — Turf Zone',
                    time: '11:00 AM – 12:00 PM',
                    status: 'pending',
                  ),
                  const SizedBox(height: 10),
                  _BookingItem(
                    customerName: 'Rahul Nair',
                    courtName: 'Court A — Green Arena',
                    time: '4:00 PM – 5:00 PM',
                    status: 'confirmed',
                  ),
                ],
              ),

            const SizedBox(height: 28),

            // ── QUICK ACTIONS ────────────────────────────────────────
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),

            _ActionButton(
              label: 'Add New Stadium',
              icon: Icons.add_business_rounded,
              isLocked: !owner.isApproved,
              onTap: () {
                if (owner.isApproved) {
                  Navigator.pushNamed(
                    context,
                    AppConstants.routeOwnerAddStadium,
                  );
                } else {
                  _showLockedSnackbar(context);
                }
              },
            ),
            const SizedBox(height: 12),
            _ActionButton(
              label: 'My Stadiums',
              icon: Icons.stadium_rounded,
              isLocked: !owner.isApproved,
              onTap: () {
                if (owner.isApproved) {
                  Navigator.pushNamed(
                    context,
                    AppConstants.routeOwnerMyStadiums,
                  );
                } else {
                  _showLockedSnackbar(context);
                }
              },
            ),
            const SizedBox(height: 12),
            _ActionButton(
              label: 'Manage Bookings',
              icon: Icons.book_online_rounded,
              isLocked: !owner.isApproved,
              onTap: () {
                if (owner.isApproved) {
                  Navigator.pushNamed(context, AppConstants.routeOwnerBookings);
                } else {
                  _showLockedSnackbar(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLockedSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Available after admin approves your account',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
      ),
    );
  }
}

// ── PENDING APPROVAL BANNER ───────────────────────────────────────────────────

class _PendingApprovalBanner extends StatelessWidget {
  const _PendingApprovalBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        border: Border.all(color: const Color(0xFFFFD166)),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.hourglass_empty_rounded,
            color: Color(0xFFE6A800),
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Pending Approval',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF7A5800),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Your stadium owner account is under review. You'll get full access once approved.",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFF7A5800),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── LOCKED CARD ───────────────────────────────────────────────────────────────

class _LockedCard extends StatelessWidget {
  const _LockedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: AppColors.textMuted,
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            'Bookings will appear here once your account is approved',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── BOOKING ITEM ──────────────────────────────────────────────────────────────

class _BookingItem extends StatelessWidget {
  final String customerName;
  final String courtName;
  final String time;
  final String status;

  const _BookingItem({
    required this.customerName,
    required this.courtName,
    required this.time,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isConfirmed = status == 'confirmed';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isConfirmed ? AppColors.badgeBg : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
            ),
            child: Icon(
              isConfirmed
                  ? Icons.check_circle_outline_rounded
                  : Icons.hourglass_empty_rounded,
              color: isConfirmed ? AppColors.primary : const Color(0xFFE6A800),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  courtName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isConfirmed ? AppColors.badgeBg : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isConfirmed ? 'Confirmed' : 'Pending',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isConfirmed
                    ? AppColors.primary
                    : const Color(0xFFE6A800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── STAT CARD ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isLocked;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(
            isLocked ? Icons.lock_outline_rounded : icon,
            color: isLocked ? AppColors.textMuted : AppColors.primary,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            isLocked ? '--' : value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isLocked ? AppColors.textMuted : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── ACTION BUTTON ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLocked;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingM,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isLocked ? AppColors.chipUnselected : AppColors.badgeBg,
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: Icon(
                isLocked ? Icons.lock_outline_rounded : icon,
                color: isLocked ? AppColors.textMuted : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isLocked ? AppColors.textMuted : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isLocked ? AppColors.textMuted : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

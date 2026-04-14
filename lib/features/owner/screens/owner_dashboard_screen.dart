import 'package:flutter/material.dart';
import '../../../app/core/theme/app_colors.dart';
import '../../../app/core/constants/app_constants.dart';
import '../data/owner_dummy_data.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final owner = dummyOwner;

    return Scaffold(
      backgroundColor: AppColors.background,
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
            onPressed: () {
              // TODO: replace with real Supabase logout later
              Navigator.of(
                context,
              ).pushReplacementNamed(AppConstants.routeSplash);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── PENDING APPROVAL BANNER ──────────────────────────────
            if (!owner.isApproved) _PendingApprovalBanner(),

            const SizedBox(height: 24),

            // ── WELCOME TEXT ─────────────────────────────────────────
            Text(
              'Welcome, ${owner.name} -ˋˏ✄┈┈┈┈ ',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Here\'s an overview of your venues',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 28),

            // ── STAT CARDS ROW ───────────────────────────────────────
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

            const SizedBox(height: 32),

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
              label: 'My Stadiums',
              icon: Icons.stadium_rounded,
              isLocked: !owner.isApproved,
              onTap: () {
                if (owner.isApproved) {
                  // TODO: navigate to My Stadiums screen
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
                  // TODO: navigate to Bookings screen
                } else {
                  _showLockedSnackbar(context);
                }
              },
            ),
            const SizedBox(height: 12),
            _ActionButton(
              label: 'Add New Stadium',
              icon: Icons.add_business_rounded,
              isLocked: !owner.isApproved,
              onTap: () {
                if (owner.isApproved) {
                  // TODO: navigate to Add Stadium screen
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
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
      ),
    );
  }
}

// ── PENDING APPROVAL BANNER WIDGET ──────────────────────────────────────────
class _PendingApprovalBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        border: Border.all(color: const Color(0xFFFFD166)),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.hourglass_empty_rounded,
            color: Color(0xFFE6A800),
            size: 22,
          ),
          const SizedBox(width: 12),
          const Expanded(
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
                  'Your stadium owner account is under review by an admin. You\'ll get full access once approved.',
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

// ── STAT CARD WIDGET ─────────────────────────────────────────────────────────
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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

// ── ACTION BUTTON WIDGET ─────────────────────────────────────────────────────
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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

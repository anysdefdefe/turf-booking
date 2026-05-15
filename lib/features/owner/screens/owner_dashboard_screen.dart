import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf_booking/app/constants/app_constants.dart';
import 'package:turf_booking/app/theme/theme_mode_selector.dart';
import 'package:turf_booking/features/auth/providers/auth_providers.dart';
import 'package:turf_booking/features/owner/data/repositories/stadium_repository.dart';
import 'package:turf_booking/features/owner/providers/stadium_providers.dart';
import 'package:turf_booking/features/owner/providers/owner_bookings_providers.dart';
import 'package:turf_booking/features/owner/widgets/storage_media.dart';
import '../widgets/owner_bottom_nav_bar.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stadiumAsync = ref.watch(currentStadiumProvider);
    final user = ref.watch(authStateProvider).value;
    final bookingsAsync = ref.watch(ownerBookingsProvider);
    final cs = Theme.of(context).colorScheme;

    return stadiumAsync.when(
      loading: () => Scaffold(
        backgroundColor: cs.surface,
        body: Center(child: CircularProgressIndicator(color: cs.primary)),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: cs.surface,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(currentStadiumProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (stadium) {
        if (stadium == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/owner/add-stadium');
          });
          return Scaffold(backgroundColor: cs.surface);
        }

        final courtsAsync = ref.watch(courtsForStadiumProvider(stadium.id));
        final courtsCount = courtsAsync.when(
          loading: () => '--',
          error: (_, _) => '--',
          data: (courts) => courts.length.toString(),
        );

        final bookingsCount = bookingsAsync.when(
          loading: () => '--',
          error: (_, _) => '--',
          data: (bookings) => bookings.totalBookings.toString(),
        );

        final revenueAmount = bookingsAsync.when(
          loading: () => '--',
          error: (_, _) => '--',
          data: (bookings) => '₹${bookings.totalRevenue.toStringAsFixed(0)}',
        );

        final firstName = user?.fullName?.split(' ').first ?? 'Owner';
        final avatarName = user?.fullName ?? user?.email ?? 'Owner';

        return Scaffold(
          backgroundColor: cs.surface,
          bottomNavigationBar: const OwnerBottomNavBar(selectedIndex: 0),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.paddingL,
                16,
                AppConstants.paddingL,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Owner Dashboard',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Welcome back, $firstName',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () => _showOwnerProfileMenu(context, ref, user),
                        child: StorageAvatar(
                          storagePath: user?.avatarUrl,
                          bucketName: AppConstants.storageImageBucket,
                          displayName: avatarName,
                          radius: 20,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cs.primary.withValues(alpha: 0.1),
                          cs.primary.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppConstants.radiusL),
                      border: Border.all(color: cs.outline),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            StorageImage(
                              storagePath: stadium.imageUrl,
                              bucketName: StadiumRepository.imageBucket,
                              width: 68,
                              height: 68,
                              borderRadius: BorderRadius.circular(18),
                              placeholder: Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: cs.outline),
                                ),
                                child: Icon(
                                  Icons.stadium_rounded,
                                  color: cs.onSurfaceVariant,
                                  size: 30,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stadium.name,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${stadium.address}, ${stadium.city}',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => context.push('/owner/edit-stadium'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── STAT CARDS ──────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Courts',
                          value: courtsCount,
                          icon: Icons.sports_tennis_rounded,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Bookings',
                          value: bookingsCount,
                          icon: Icons.calendar_today_rounded,
                          color: const Color(0xFF0EA5E9),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Revenue',
                          value: revenueAmount,
                          icon: Icons.currency_rupee_rounded,
                          color: const Color(0xFF22C55E),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── TODAY'S BOOKINGS ─────────────────────────────
                  Text(
                    "Today's Bookings",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 14),

                  bookingsAsync.when(
                    loading: () => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(color: cs.primary),
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Text(
                        'Error: $err',
                        style: TextStyle(color: cs.error),
                      ),
                    ),
                    data: (bookings) {
                      final todayStr = DateTime.now()
                          .toIso8601String()
                          .substring(0, 10);
                      final todayBookingsList = bookings
                          .where(
                            (b) =>
                                b.bookingDate == todayStr &&
                                b.status != 'cancelled',
                          )
                          .toList();

                      if (todayBookingsList.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainer,
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusM,
                            ),
                            border: Border.all(color: cs.outline),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_available_rounded,
                                color: cs.onSurfaceVariant,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No bookings yet',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: todayBookingsList.length.clamp(
                          0,
                          3,
                        ), // Show max 3 previews
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final b = todayBookingsList[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainer,
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusM,
                              ),
                              border: Border.all(color: cs.outline),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                      AppConstants.radiusS,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.person_outline_rounded,
                                    color: cs.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        b.customerName ?? 'Unknown',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      Text(
                                        '${b.courtName} • ${b.startTime.substring(0, 5)}',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // ── QUICK ACTIONS ───────────────────────────────
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _ActionButton(
                    label: 'Manage Courts',
                    subtitle: '$courtsCount courts registered',
                    icon: Icons.stadium_rounded,
                    onTap: () => context.go('/owner/manage'),
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    label: 'View Bookings',
                    subtitle: 'Track customer reservations',
                    icon: Icons.book_online_rounded,
                    onTap: () => context.go('/owner/bookings'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

void _showOwnerProfileMenu(BuildContext context, WidgetRef ref, dynamic user) {
  final name = user?.fullName ?? user?.email ?? 'Owner';
  final avatar = user?.avatarUrl as String?;
  showModalBottomSheet(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _OwnerProfileMenu(
      name: name,
      email: user?.email ?? '',
      avatarUrl: avatar,
      onLogout: () async {
        Navigator.pop(context);
        await Supabase.instance.client.auth.signOut();
        if (context.mounted) context.go(AppConstants.routeLogin);
      },
      onSwitch: () {
        Navigator.pop(context);
        context.go(AppConstants.routeModeSelection);
      },
    ),
  );
}

class _OwnerProfileMenu extends StatelessWidget {
  final String name;
  final String email;
  final String? avatarUrl;
  final VoidCallback onLogout;
  final VoidCallback onSwitch;

  const _OwnerProfileMenu({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.onLogout,
    required this.onSwitch,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom:
              MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  StorageAvatar(
                    storagePath: avatarUrl,
                    bucketName: AppConstants.storageImageBucket,
                    displayName: name,
                    radius: 36,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ThemeModeSelector(title: 'Appearance'),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: cs.surface,
                        side: BorderSide(color: cs.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: onSwitch,
                      icon: Icon(Icons.swap_horiz, color: cs.primary),
                      label: Text(
                        'Switch Role',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: cs.surface,
                        side: BorderSide(color: cs.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: onLogout,
                      icon: Icon(Icons.logout_rounded, color: cs.error),
                      label: Text(
                        'Logout',
                        style: TextStyle(
                          color: cs.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── STAT CARD ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: cs.onSurfaceVariant,
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
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingM,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: cs.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: Icon(icon, color: cs.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

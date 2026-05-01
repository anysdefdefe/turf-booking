import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:turf_booking/app/theme/app_colors.dart';
import 'package:turf_booking/app/constants/app_constants.dart';
import 'package:turf_booking/features/owner/data/models/court_model.dart';
import 'package:turf_booking/features/owner/data/repositories/stadium_repository.dart';
import 'package:turf_booking/features/owner/providers/stadium_providers.dart';
import 'package:turf_booking/features/owner/widgets/storage_media.dart';
import '../widgets/owner_bottom_nav_bar.dart';

// ── Sport icon helper ─────────────────────────────────────────────────────────

IconData _sportIcon(String sportType) {
  switch (sportType.toLowerCase()) {
    case 'football':
    case 'soccer':
      return Icons.sports_soccer_rounded;
    case 'badminton':
      return Icons.sports_tennis_rounded;
    case 'cricket':
      return Icons.sports_cricket_rounded;
    case 'basketball':
      return Icons.sports_basketball_rounded;
    case 'volleyball':
      return Icons.sports_volleyball_rounded;
    case 'padel':
    case 'tennis':
      return Icons.sports_tennis_rounded;
    default:
      return Icons.sports_rounded;
  }
}

const _kSportOptions = [
  'Football',
  'Badminton',
  'Cricket',
  'Basketball',
  'Volleyball',
  'Tennis',
  'Padel',
];

const _kEquipmentOptions = [
  'Rackets',
  'Balls',
  'Nets',
  'Gloves',
  'Helmets',
  'Pads',
  'Stumps',
  'Cones',
  'Bibs',
  'First Aid Kit',
  'Water Station',
  'Scoreboard',
];

// ── Root screen ───────────────────────────────────────────────────────────────

class OwnerStadiumManageScreen extends ConsumerWidget {
  const OwnerStadiumManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stadiumAsync = ref.watch(currentStadiumProvider);

    return stadiumAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(currentStadiumProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
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
          return const Scaffold(backgroundColor: AppColors.background);
        }

        final courtsAsync = ref.watch(courtsForStadiumProvider(stadium.id));

        return courtsAsync.when(
          loading: () => const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (err, _) => Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: Text('Failed to load courts: $err')),
          ),
          data: (courts) {
            final minPrice = courts.isEmpty
                ? null
                : courts
                      .map((c) => c.pricePerHour)
                      .reduce((a, b) => a < b ? a : b);

            final defaultOpen = courts.isNotEmpty
                ? courts.first.openTime
                : '06:00:00';
            final defaultClose = courts.isNotEmpty
                ? courts.first.closeTime
                : '22:00:00';

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.light,
              child: Scaffold(
                backgroundColor: Colors.white,
                bottomNavigationBar: const OwnerBottomNavBar(selectedIndex: 1),
                body: Column(
                  children: [
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          // Hero image
                          SliverToBoxAdapter(
                            child: _HeroImage(
                              imageUrl: stadium.imageUrl,
                              onEdit: () => context.push('/owner/edit-stadium'),
                            ),
                          ),
                          // Venue details
                          SliverToBoxAdapter(
                            child: _VenueDetails(
                              name: stadium.name,
                              address: stadium.address,
                              city: stadium.city,
                              description: stadium.description,
                              amenities: stadium.amenities,
                              minPrice: minPrice,
                            ),
                          ),
                          // Sport Types
                          if (courts.isNotEmpty)
                            SliverToBoxAdapter(
                              child: _SportTypesSection(courts: courts),
                            ),
                          // Courts management
                          SliverToBoxAdapter(
                            child: _CourtsSection(
                              courts: courts,
                              stadiumId: stadium.id,
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        ],
                      ),
                    ),
                    // CTA bar
                    _CtaBar(
                      stadiumId: stadium.id,
                      defaultOpenTime: defaultOpen,
                      defaultCloseTime: defaultClose,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── HERO IMAGE ────────────────────────────────────────────────────────────────

class _HeroImage extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback onEdit;

  const _HeroImage({required this.imageUrl, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 240,
          width: double.infinity,
          child: StorageImage(
            storagePath: imageUrl,
            bucketName: StadiumRepository.imageBucket,
            width: double.infinity,
            height: 240,
            borderRadius: BorderRadius.zero,
            placeholder: _PlaceholderHero(),
          ),
        ),
        // Gradient
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
          ),
        ),
        // Back button
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 14,
          child: GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/owner/dashboard');
              }
            },
            child: _CircleButton(
              icon: Icons.chevron_left_rounded,
              iconColor: Colors.black87,
            ),
          ),
        ),
        // Edit button
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 14,
          child: GestureDetector(
            onTap: onEdit,
            child: _CircleButton(
              icon: Icons.edit_outlined,
              iconColor: AppColors.primary,
              iconSize: 18,
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final double iconSize;

  const _CircleButton({
    required this.icon,
    required this.iconColor,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8),
        ],
      ),
      child: Icon(icon, color: iconColor, size: iconSize),
    );
  }
}

class _PlaceholderHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFD0EED8),
      child: const Center(
        child: Icon(Icons.stadium_rounded, size: 64, color: AppColors.primary),
      ),
    );
  }
}

// ── VENUE DETAILS ─────────────────────────────────────────────────────────────

class _VenueDetails extends StatelessWidget {
  final String name;
  final String address;
  final String city;
  final String? description;
  final List<String> amenities;
  final double? minPrice;

  const _VenueDetails({
    required this.name,
    required this.address,
    required this.city,
    required this.description,
    required this.amenities,
    required this.minPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingL,
        18,
        AppConstants.paddingL,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          if (minPrice != null)
            Text(
              '₹ ${minPrice!.toStringAsFixed(0)} onwards',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 15,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '$address, $city',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'About Venue',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            (description != null && description!.trim().isNotEmpty)
                ? description!
                : 'No description provided for this venue yet.',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (amenities.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Amenities',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: amenities
                  .map((a) => _AmenityChip(label: a))
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

// ── SPORT TYPES ───────────────────────────────────────────────────────────────

class _SportTypesSection extends StatelessWidget {
  final List<CourtModel> courts;
  const _SportTypesSection({required this.courts});

  @override
  Widget build(BuildContext context) {
    final sports = courts.map((c) => c.sportType).toSet().toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingL,
        20,
        AppConstants.paddingL,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sport Types',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sports
                .map((s) => _SportChip(sport: s))
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

// ── COURTS SECTION ────────────────────────────────────────────────────────────

class _CourtsSection extends ConsumerWidget {
  final List<CourtModel> courts;
  final String stadiumId;

  const _CourtsSection({required this.courts, required this.stadiumId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingL,
        24,
        AppConstants.paddingL,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Courts',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (courts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No courts added yet. Tap "Add New Court" below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            )
          else
            ...courts.map((c) => _CourtTile(court: c, stadiumId: stadiumId)),
        ],
      ),
    );
  }
}

// ── CTA BAR ───────────────────────────────────────────────────────────────────

class _CtaBar extends StatelessWidget {
  final String stadiumId;
  final String defaultOpenTime;
  final String defaultCloseTime;

  const _CtaBar({
    required this.stadiumId,
    required this.defaultOpenTime,
    required this.defaultCloseTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: AppConstants.paddingL,
        right: AppConstants.paddingL,
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 10,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton.icon(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) => _AddCourtSheet(
                stadiumId: stadiumId,
                defaultOpenTime: defaultOpenTime,
                defaultCloseTime: defaultCloseTime,
                scrollController: scrollController,
              ),
            ),
          ),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text(
            'Add New Court',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1A1A1A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

// ── COURT TILE ────────────────────────────────────────────────────────────────

class _CourtTile extends ConsumerWidget {
  final CourtModel court;
  final String stadiumId;

  const _CourtTile({required this.court, required this.stadiumId});

  // ── Deactivate (soft-delete) ─────────────────────────────────────────────
  Future<void> _confirmDeactivate(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Deactivate court?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '"${court.name}" will be hidden from customers, but all existing bookings will remain safe.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    foregroundColor: AppColors.textPrimary,
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                  child: const Text(
                    'Deactivate',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(stadiumRepositoryProvider)
          .updateCourt(courtId: court.id, isActive: false);
      ref.invalidate(courtsForStadiumProvider(stadiumId));
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '"${court.name}" deactivated — hidden from customers',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Failed: $e',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // ── Activate (re-enable) ─────────────────────────────────────────────────
  Future<void> _confirmActivate(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.green,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Activate court?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '"${court.name}" will be visible to customers again and available for new bookings.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    foregroundColor: AppColors.textPrimary,
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                  child: const Text(
                    'Activate',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(stadiumRepositoryProvider)
          .updateCourt(courtId: court.id, isActive: true);
      ref.invalidate(courtsForStadiumProvider(stadiumId));
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '"${court.name}" activated — now visible to customers',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Failed: $e',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sport icon
          StorageImage(
            storagePath: court.imageUrl,
            bucketName: StadiumRepository.imageBucket,
            width: 40,
            height: 40,
            borderRadius: BorderRadius.circular(20),
            placeholder: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.badgeBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _sportIcon(court.sportType),
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  court.name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${court.sportType} · ₹${court.pricePerHour.toStringAsFixed(0)}/hr  ·  ${court.openTime.substring(0, 5)}–${court.closeTime.substring(0, 5)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Status chip
          _StatusChip(isActive: court.isActive),
          const SizedBox(width: 8),

          // Edit button
          GestureDetector(
            onTap: () => context.push('/owner/edit-court/${court.id}'),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.edit_outlined,
                size: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Activate / Deactivate toggle button
          GestureDetector(
            onTap: () => court.isActive
                ? _confirmDeactivate(context, ref)
                : _confirmActivate(context, ref),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: court.isActive
                    ? AppColors.error.withValues(alpha: 0.08)
                    : Colors.green.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                court.isActive
                    ? Icons.block_rounded
                    : Icons.check_circle_outline_rounded,
                size: 15,
                color: court.isActive ? AppColors.error : Colors.green.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── ADD COURT BOTTOM SHEET ────────────────────────────────────────────────────

class _AddCourtSheet extends ConsumerStatefulWidget {
  final String stadiumId;
  final String defaultOpenTime;
  final String defaultCloseTime;
  final ScrollController? scrollController;

  const _AddCourtSheet({
    required this.stadiumId,
    required this.defaultOpenTime,
    required this.defaultCloseTime,
    this.scrollController,
  });

  @override
  ConsumerState<_AddCourtSheet> createState() => _AddCourtSheetState();
}

class _AddCourtSheetState extends ConsumerState<_AddCourtSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imagePicker = ImagePicker();
  String? _selectedSport;
  File? _selectedImage;
  late TimeOfDay _openTime;
  late TimeOfDay _closeTime;
  bool _isSaving = false;
  final List<String> _selectedEquipments = [];

  @override
  void initState() {
    super.initState();
    _openTime = _parseTime(widget.defaultOpenTime);
    _closeTime = _parseTime(widget.defaultCloseTime);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    widget.scrollController?.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> _pickImage() async {
    final xfile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (xfile != null && mounted) {
      setState(() => _selectedImage = File(xfile.path));
    }
  }

  Future<void> _pickTime(bool isOpen) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpen ? _openTime : _closeTime,
    );
    if (picked != null && mounted) {
      setState(() {
        if (isOpen) {
          _openTime = picked;
        } else {
          _closeTime = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());

    if (name.isEmpty) {
      _snack('Court name is required');
      return;
    }
    if (_selectedSport == null) {
      _snack('Please select a sport type');
      return;
    }
    if (price == null || price <= 0) {
      _snack('Enter a valid price per hour');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(stadiumRepositoryProvider)
          .addCourt(
            stadiumId: widget.stadiumId,
            name: name,
            sportType: _selectedSport!,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            pricePerHour: price,
            equipments: List.unmodifiable(_selectedEquipments),
            openTime:
                '${_openTime.hour.toString().padLeft(2, '0')}:${_openTime.minute.toString().padLeft(2, '0')}:00',
            closeTime:
                '${_closeTime.hour.toString().padLeft(2, '0')}:${_closeTime.minute.toString().padLeft(2, '0')}:00',
            imageFile: _selectedImage,
          );
      // Invalidate while ref is still valid (widget still mounted)
      ref.invalidate(courtsForStadiumProvider(widget.stadiumId));
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '✓ Court added',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) _snack('Failed to add court: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 24),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Title
            const Text(
              'Add New Court',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Court name
            _label('Court Name'),
            _field(_nameController, hint: 'e.g. Court A'),
            const SizedBox(height: 16),

            _label('About / Description'),
            _field(
              _descriptionController,
              hint: 'Short description for customers',
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            _label('Court Image'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  border: Border.all(color: AppColors.divider),
                ),
                child: _selectedImage == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 30,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap to add court image',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      )
                    : Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusM,
                              ),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 12,
                            child: _courtImagePill('Tap to change'),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Sport type
            _label('Sport Type'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kSportOptions.map((sport) {
                final selected = _selectedSport == sport;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSport = sport),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.divider,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _sportIcon(sport),
                          size: 13,
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          sport,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Price
            _label('Price per Hour (₹)'),
            _field(
              _priceController,
              hint: 'e.g. 800',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _TimeField(
                    label: 'Start Time',
                    time: _openTime,
                    onTap: () => _pickTime(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeField(
                    label: 'End Time',
                    time: _closeTime,
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Equipments
            _label('Equipments Available'),
            const SizedBox(height: 2),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kEquipmentOptions.map((eq) {
                final selected = _selectedEquipments.contains(eq);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedEquipments.remove(eq);
                    } else {
                      _selectedEquipments.add(eq);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.10)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.divider,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selected) ...[
                          Icon(
                            Icons.check_rounded,
                            size: 12,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          eq,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _isSaving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Add Court',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    ),
  );

  Widget _field(
    TextEditingController controller, {
    String hint = '',
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    maxLines: maxLines,
    style: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      color: AppColors.textPrimary,
    ),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: AppColors.textMuted,
      ),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
  );

  Widget _courtImagePill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _TimeField({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── AMENITY CHIP ──────────────────────────────────────────────────────────────

class _AmenityChip extends StatelessWidget {
  final String label;
  const _AmenityChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.divider, width: 1.2),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

// ── SPORT CHIP ────────────────────────────────────────────────────────────────

class _SportChip extends StatelessWidget {
  final String sport;
  const _SportChip({required this.sport});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_sportIcon(sport), size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            sport,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── STATUS CHIP ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final bool isActive;
  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.green.shade700 : Colors.red.shade400,
        ),
      ),
    );
  }
}

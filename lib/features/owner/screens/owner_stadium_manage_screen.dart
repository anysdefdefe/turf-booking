import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:turf_booking/app/theme/app_colors.dart';
import 'package:turf_booking/app/constants/app_constants.dart';
import 'package:turf_booking/features/owner/data/models/court_model.dart';
import 'package:turf_booking/features/owner/providers/stadium_providers.dart';
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
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.textMuted),
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
            // Lowest price among courts for "onwards" display
            final minPrice = courts.isEmpty
                ? null
                : courts
                    .map((c) => c.pricePerHour)
                    .reduce((a, b) => a < b ? a : b);

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.light,
              child: Scaffold(
                backgroundColor: Colors.white,
                bottomNavigationBar: const OwnerBottomNavBar(selectedIndex: 1),
                body: Column(
                  children: [
                    // ── scrollable content ────────────────────────────
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          // ── Hero image ──────────────────────────────
                          SliverToBoxAdapter(
                            child: _HeroImage(
                              imageUrl: stadium.imageUrl,
                              onEdit: () =>
                                  context.push('/owner/edit-stadium'),
                            ),
                          ),

                          // ── Venue details ───────────────────────────
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

                          // ── Sport Types ─────────────────────────────
                          if (courts.isNotEmpty)
                            SliverToBoxAdapter(
                              child: _SportTypesSection(courts: courts),
                            ),

                          // ── Courts (owner management) ────────────────
                          SliverToBoxAdapter(
                            child: _CourtsSection(
                              courts: courts,
                              stadiumId: stadium.id,
                            ),
                          ),

                          const SliverToBoxAdapter(
                            child: SizedBox(height: 24),
                          ),
                        ],
                      ),
                    ),

                    // ── CTA bar ───────────────────────────────────────
                    _CtaBar(
                      courts: courts,
                      onAddCourt: () =>
                          context.push('/owner/edit-stadium'),
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
        // Image
        SizedBox(
          height: 240,
          width: double.infinity,
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => _PlaceholderHero(),
                )
              : _PlaceholderHero(),
        ),

        // Dark gradient at bottom for readability
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
              if (context.canPop()) context.pop();
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.chevron_left_rounded,
                  color: Colors.black87, size: 22),
            ),
          ),
        ),

        // Edit button (top right)
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 14,
          child: GestureDetector(
            onTap: onEdit,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.edit_outlined,
                  color: AppColors.primary, size: 18),
            ),
          ),
        ),
      ],
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
          AppConstants.paddingL, 18, AppConstants.paddingL, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
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

          // Price
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

          // Location
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '$address, $city',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // About Venue
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

          // Amenities
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

// ── SPORT TYPES SECTION ───────────────────────────────────────────────────────

class _SportTypesSection extends StatelessWidget {
  final List<CourtModel> courts;

  const _SportTypesSection({required this.courts});

  @override
  Widget build(BuildContext context) {
    // Unique sport types
    final sports = courts.map((c) => c.sportType).toSet().toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppConstants.paddingL, 20, AppConstants.paddingL, 0),
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
            children:
                sports.map((s) => _SportChip(sport: s)).toList(growable: false),
          ),
        ],
      ),
    );
  }
}

// ── COURTS SECTION (owner management) ────────────────────────────────────────

class _CourtsSection extends StatelessWidget {
  final List<CourtModel> courts;
  final String stadiumId;

  const _CourtsSection({
    required this.courts,
    required this.stadiumId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppConstants.paddingL, 24, AppConstants.paddingL, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              // Add court button
              GestureDetector(
                onTap: () => context.push('/owner/add-stadium'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.badgeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add_rounded,
                          size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Add Court',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (courts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No courts added yet',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            )
          else
            ...courts.map((c) => _CourtTile(court: c)),
        ],
      ),
    );
  }
}

// ── CTA BAR ───────────────────────────────────────────────────────────────────

class _CtaBar extends StatelessWidget {
  final List<CourtModel> courts;
  final VoidCallback onAddCourt;

  const _CtaBar({required this.courts, required this.onAddCourt});

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
          onPressed: () {
            // Owner: navigates to court management / add court
            context.push('/owner/add-stadium');
          },
          icon: const Icon(Icons.sports_rounded, size: 18),
          label: const Text(
            'Manage: choose a sport type',
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

class _CourtTile extends StatelessWidget {
  final CourtModel court;
  const _CourtTile({required this.court});

  @override
  Widget build(BuildContext context) {
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
          // Sport icon circle
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.badgeBg,
              shape: BoxShape.circle,
            ),
            child: Icon(_sportIcon(court.sportType),
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),

          // Court info
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
                ),
                const SizedBox(height: 2),
                Text(
                  '${court.sportType} · ₹${court.pricePerHour.toStringAsFixed(0)}/hr  ·  ${court.openTime.substring(0, 5)}–${court.closeTime.substring(0, 5)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
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
              child: const Icon(Icons.edit_outlined,
                  size: 15, color: AppColors.textSecondary),
            ),
          ),
        ],
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

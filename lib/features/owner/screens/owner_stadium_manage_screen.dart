import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:turf_booking/app/theme/app_colors.dart';
import 'package:turf_booking/app/constants/app_constants.dart';
import 'owner_my_stadiums_screen.dart'; // import StadiumModel

// ─────────────────────────────────────────────────────────────────────────────
// COURT MODEL
// ─────────────────────────────────────────────────────────────────────────────

class CourtModel {
  final String id;
  final String name;
  final String sport;
  final double pricePerHour;
  final bool isAvailable;

  const CourtModel({
    required this.id,
    required this.name,
    required this.sport,
    required this.pricePerHour,
    required this.isAvailable,
  });
}

// Mock courts per stadium id
const Map<String, List<CourtModel>> _mockCourts = {
  '1': [
    CourtModel(
      id: 'c1',
      name: 'Court A',
      sport: 'Football',
      pricePerHour: 800,
      isAvailable: true,
    ),
    CourtModel(
      id: 'c2',
      name: 'Court B',
      sport: 'Cricket',
      pricePerHour: 600,
      isAvailable: true,
    ),
    CourtModel(
      id: 'c3',
      name: 'Court C',
      sport: 'Badminton',
      pricePerHour: 400,
      isAvailable: false,
    ),
  ],
  '2': [
    CourtModel(
      id: 'c4',
      name: 'Main Court',
      sport: 'Football',
      pricePerHour: 1000,
      isAvailable: true,
    ),
    CourtModel(
      id: 'c5',
      name: 'Side Court',
      sport: 'Football',
      pricePerHour: 750,
      isAvailable: false,
    ),
  ],
  '3': [
    CourtModel(
      id: 'c6',
      name: 'Court 1',
      sport: 'Tennis',
      pricePerHour: 500,
      isAvailable: true,
    ),
  ],
};

// ─────────────────────────────────────────────────────────────────────────────
// MANAGE SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class OwnerStadiumManageScreen extends StatelessWidget {
  final StadiumModel stadium;

  const OwnerStadiumManageScreen({super.key, required this.stadium});

  @override
  Widget build(BuildContext context) {
    final courts = _mockCourts[stadium.id] ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(stadium.name),
        actions: [
          // ── Edit Stadium button in top-right ────────────────
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () {
                context.push(
                  '/owner/stadium/${stadium.id}/edit',
                  extra: stadium,
                );
              },
              icon: const Icon(
                Icons.edit_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              label: const Text(
                'Edit Stadium',
                style: TextStyle(
                  color: AppColors.primary,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Stadium photo strip ──────────────────────────────
          SliverToBoxAdapter(child: _StadiumPhotoStrip(stadium: stadium)),

          // ── Section header ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.paddingL,
                20,
                AppConstants.paddingL,
                8,
              ),
              child: Row(
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
                  // ── Add court ──────────────────────────────
                  GestureDetector(
                    onTap: () {
                      context.push(
                        '/owner/stadium/${stadium.id}/add-court',
                        extra: stadium,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, size: 14, color: AppColors.primary),
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
            ),
          ),

          // ── Courts list ──────────────────────────────────────
          courts.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No courts added yet',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingL,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _CourtTile(
                        court: courts[index],
                        stadiumId: stadium.id,
                      ),
                      childCount: courts.length,
                    ),
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STADIUM PHOTO STRIP (horizontal scroll)
// ─────────────────────────────────────────────────────────────────────────────

class _StadiumPhotoStrip extends StatelessWidget {
  final StadiumModel stadium;
  const _StadiumPhotoStrip({required this.stadium});

  @override
  Widget build(BuildContext context) {
    if (stadium.imageUrls.isEmpty) {
      return Container(
        height: 180,
        color: stadium.placeholderColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 36,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 8),
              Text(
                'No photos — tap Edit Stadium to add',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingL,
          vertical: 12,
        ),
        itemCount: stadium.imageUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            stadium.imageUrls[i],
            width: 220,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 220,
              color: stadium.placeholderColor,
              child: const Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 32,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COURT TILE
// ─────────────────────────────────────────────────────────────────────────────

class _CourtTile extends StatelessWidget {
  final CourtModel court;
  final String stadiumId;
  const _CourtTile({required this.court, required this.stadiumId});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // Sport icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.sports, color: AppColors.primary, size: 22),
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
                  '${court.sport} · ₹${court.pricePerHour.toStringAsFixed(0)}/hr',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Availability chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: court.isAvailable
                  ? Colors.green.withValues(alpha: 0.12)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              court.isAvailable ? 'Available' : 'Unavailable',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: court.isAvailable ? Colors.green : Colors.redAccent,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Edit button
          GestureDetector(
            onTap: () {
              context.push(
                '/owner/stadium/$stadiumId/court/${court.id}/edit',
                extra: court,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.edit_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

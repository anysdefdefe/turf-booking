import 'package:flutter/material.dart';
import 'package:turf_booking/app/theme/app_colors.dart';
import 'package:turf_booking/app/constants/app_constants.dart';
import '../widgets/owner_bottom_nav_bar.dart';
import 'package:go_router/go_router.dart';

class StadiumModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final bool isActive;
  final int courtsCount;
  final Color placeholderColor;
  final List<String> imageUrls; // NEW: list of photo URLs

  const StadiumModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.isActive,
    required this.courtsCount,
    required this.placeholderColor,
    this.imageUrls = const [],
  });
}

const List<StadiumModel> _mockStadiums = [
  StadiumModel(
    id: '1',
    name: 'Green Arena',
    address: '12, MG Road',
    city: 'Bengaluru',
    isActive: true,
    courtsCount: 3,
    placeholderColor: Color(0xFF1D9E75),
    imageUrls: [
      'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800',
      'https://images.unsplash.com/photo-1556056504-5c7696c4c28d?w=800',
    ],
  ),
  StadiumModel(
    id: '2',
    name: 'Turf Zone',
    address: '45, Koramangala',
    city: 'Bengaluru',
    isActive: true,
    courtsCount: 2,
    placeholderColor: Color(0xFF378ADD),
    imageUrls: [
      'https://images.unsplash.com/photo-1459865264687-595d652de67e?w=800',
    ],
  ),
  StadiumModel(
    id: '3',
    name: 'PlayField Hub',
    address: '8, Whitefield',
    city: 'Bengaluru',
    isActive: false,
    courtsCount: 1,
    placeholderColor: Color(0xFF888780),
    imageUrls: [],
  ),
];

class OwnerMyStadiumsScreen extends StatelessWidget {
  const OwnerMyStadiumsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const OwnerBottomNavBar(selectedIndex: 1),
      // ── FAB replaces AppBar Add button ──────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/owner/add-stadium'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Stadium',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: AppBar(
        title: const Text('My Stadiums'),
        // No more "Add" action here
      ),
      body: _mockStadiums.isEmpty
          ? _buildEmpty()
          : ListView.separated(
              // Extra bottom padding so FAB doesn't overlap last card
              padding: const EdgeInsets.fromLTRB(
                AppConstants.paddingL,
                AppConstants.paddingL,
                AppConstants.paddingL,
                100,
              ),
              itemCount: _mockStadiums.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _StadiumCard(stadium: _mockStadiums[index]),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.stadium_outlined, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text(
            'No stadiums yet',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + Add Stadium below to get started',
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

// ─────────────────────────────────────────────────────────────────────────────
// STADIUM CARD
// ─────────────────────────────────────────────────────────────────────────────

class _StadiumCard extends StatefulWidget {
  final StadiumModel stadium;
  const _StadiumCard({required this.stadium});

  @override
  State<_StadiumCard> createState() => _StadiumCardState();
}

class _StadiumCardState extends State<_StadiumCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stadium = widget.stadium;
    final hasImages = stadium.imageUrls.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── IMAGE CAROUSEL (or placeholder) ───────────────────
          SizedBox(
            height: 160,
            child: Stack(
              children: [
                // Photo carousel or solid placeholder
                hasImages
                    ? PageView.builder(
                        controller: _pageController,
                        itemCount: stadium.imageUrls.length,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        itemBuilder: (context, i) => Image.network(
                          stadium.imageUrls[i],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: stadium.placeholderColor,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded /
                                            progress.expectedTotalBytes!
                                      : null,
                                  color: Colors.white54,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => _PlaceholderImage(
                            color: stadium.placeholderColor,
                          ),
                        ),
                      )
                    : _PlaceholderImage(color: stadium.placeholderColor),

                // Page dots (only if multiple images)
                if (hasImages && stadium.imageUrls.length > 1)
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        stadium.imageUrls.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentPage == i ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentPage == i
                                ? Colors.white
                                : Colors.white54,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Active / Inactive badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: stadium.isActive
                          ? Colors.green.withValues(alpha: 0.85)
                          : Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: stadium.isActive
                                ? Colors.greenAccent
                                : Colors.white54,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          stadium.isActive ? 'Active' : 'Inactive',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Photo count badge (bottom-left)
                if (hasImages)
                  Positioned(
                    bottom: 8,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.photo_library_outlined,
                            size: 12,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${stadium.imageUrls.length}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── CARD CONTENT ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stadium.name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${stadium.address}, ${stadium.city}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.sports_tennis,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${stadium.courtsCount} court${stadium.courtsCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    // ── Manage button now navigates ──────────────
                    GestureDetector(
                      onTap: () {
                        context.push(
                          '/owner/stadium/${stadium.id}/manage',
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
                        child: const Text(
                          'Manage →',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLACEHOLDER IMAGE WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceholderImage extends StatelessWidget {
  final Color color;
  const _PlaceholderImage({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color,
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.stadium_rounded,
              size: 56,
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                Text(
                  'No photos added',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
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

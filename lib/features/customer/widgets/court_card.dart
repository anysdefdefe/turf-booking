import 'package:flutter/material.dart';

import '../../../app/constants/app_constants.dart';
import '../../../app/theme/app_colors.dart';
import '../data/models/court_model.dart';
import 'sport_icon_mapper.dart';

class CourtCard extends StatelessWidget {
  final Court court;
  final VoidCallback onTap;
  final bool isLiked;
  final VoidCallback? onLikeToggle;

  const CourtCard({
    super.key,
    required this.court,
    required this.onTap,
    this.isLiked = false,
    this.onLikeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CourtImage(court: court),
            _CourtInfo(
              court: court,
              isLiked: isLiked,
              onLikeToggle: onLikeToggle,
            ),
          ],
        ),
      ),
    );
  }
}

class _CourtImage extends StatelessWidget {
  final Court court;

  const _CourtImage({required this.court});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusL),
          ),
          child: Image.network(
            court.imageUrl,
            height: AppConstants.cardImageHeight,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (ctx, child, progress) {
              if (progress == null) return child;
              return Container(
                height: AppConstants.cardImageHeight,
                color: AppColors.divider,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
            errorBuilder: (_, _, _) => Container(
              height: AppConstants.cardImageHeight,
              color: AppColors.divider,
              child: const Icon(
                Icons.sports_tennis_rounded,
                size: 44,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: _DistanceChip(distanceKm: court.distanceKm),
        ),
      ],
    );
  }
}

class _DistanceChip extends StatelessWidget {
  final double distanceKm;

  const _DistanceChip({required this.distanceKm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.near_me_rounded,
            color: AppColors.textSecondary,
            size: 11,
          ),
          const SizedBox(width: 4),
          Text(
            '${distanceKm.toStringAsFixed(1)} km',
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: AppColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CourtInfo extends StatelessWidget {
  final Court court;
  final bool isLiked;
  final VoidCallback? onLikeToggle;

  const _CourtInfo({
    required this.court,
    required this.isLiked,
    required this.onLikeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final visibleSports = <_SportBadgeModel>[];
    final seenIconKeys = <String>{};
    for (final sport in court.courtTypes) {
      final badge = _SportBadgeModel(
        label: sport,
        icon: sportIconForName(sport),
      );
      final iconKey =
          '${badge.icon.codePoint}:${badge.icon.fontFamily ?? ''}:${badge.icon.fontPackage ?? ''}';
      if (seenIconKeys.add(iconKey)) {
        visibleSports.add(badge);
      }
    }

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  court.name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '₹${court.pricePerHour.toInt()}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const TextSpan(
                      text: '/hr',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onLikeToggle != null) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: onLikeToggle,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      border: Border.all(
                        color: isLiked ? AppColors.primary : AppColors.divider,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 15,
                      color: isLiked
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ...visibleSports
                  .take(3)
                  .map(
                    (badge) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Tooltip(
                        message: badge.label,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: AppColors.divider,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            badge.icon,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
              if (visibleSports.length > 3)
                Text(
                  '+${visibleSports.length - 3} more',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SportBadgeModel {
  final String label;
  final IconData icon;

  const _SportBadgeModel({required this.label, required this.icon});
}

import 'package:flutter/material.dart';
import '../../../app/constants/app_constants.dart';
import '../../../app/theme/app_colors.dart';
import '../data/models/court_model.dart';

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
                size: 48,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
        Positioned(
          top: 14,
          left: 14,
          child: _AvailabilityBadge(isAvailable: court.isAvailable),
        ),
        Positioned(
          top: 14,
          right: 14,
          child: _DistanceChip(distanceKm: court.distanceKm),
        ),
      ],
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final bool isAvailable;
  const _AvailabilityBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAvailable ? AppColors.primary : Colors.red.shade300,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isAvailable ? 'Available' : 'Booked',
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DistanceChip extends StatelessWidget {
  final double distanceKm;
  const _DistanceChip({required this.distanceKm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.near_me_rounded,
            color: AppColors.textSecondary,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            '${distanceKm.toStringAsFixed(1)} km',
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: AppColors.textSecondary,
              fontSize: 11,
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
    return Padding(
      padding: const EdgeInsets.all(16),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const TextSpan(
                      text: '/hr',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
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
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 30,
                    height: 30,
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
                      size: 18,
                      color: isLiked
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            court.stadiumName,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${court.place}, ${court.city}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            court.courtTypes.join('  •  '),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

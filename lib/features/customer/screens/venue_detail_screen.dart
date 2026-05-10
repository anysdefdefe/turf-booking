import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants/app_constants.dart';
import '../../../app/theme/app_colors.dart';
import 'package:turf_booking/features/owner/widgets/storage_media.dart';
import 'package:turf_booking/features/owner/data/repositories/stadium_repository.dart';
import '../data/models/court_model.dart';
import '../data/models/stadium_model.dart';
import '../data/repositories/court_repository.dart';
import '../widgets/detail_section_title.dart';
import '../widgets/sport_icon_mapper.dart';

class VenueDetailScreen extends StatefulWidget {
  final Stadium venue;

  const VenueDetailScreen({super.key, required this.venue});

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen> {
  final CourtRepository _repo = CourtRepository.instance;

  List<Court> get _venueCourts => _repo.getCourtsByStadium(widget.venue.id);

  int? get _lowestPricePerHour {
    if (_venueCourts.isEmpty) {
      return null;
    }
    final lowest = _venueCourts
        .map((court) => court.pricePerHour)
        .reduce((a, b) => a < b ? a : b);
    return lowest.toInt();
  }

  List<String> get _sportTypes {
    final sports = <String>{};
    for (final court in _venueCourts) {
      sports.addAll(court.courtTypes);
    }
    final sorted = sports.toList(growable: false)..sort();
    return sorted;
  }

  void _openSportTypePicker() {
    final sports = _sportTypes;
    if (sports.isEmpty) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (context) {
        return ListView.separated(
          shrinkWrap: true,
          itemCount: sports.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, index) {
            final sport = sports[index];
            return ListTile(
              leading: Icon(sportIconForName(sport), color: AppColors.primary),
              title: Text(
                sport,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).pop();
                _openCourtsForSport(sport);
              },
            );
          },
        );
      },
    );
  }

  void _openCourtsForSport(String sportType) {
    final courts = _venueCourts
        .where((court) => court.courtTypes.contains(sportType))
        .toList(growable: false);

    if (courts.isEmpty) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$sportType courts',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: courts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final court = courts[index];
                    final subtitle =
                        '${court.openTime} - ${court.closeTime}  •  ₹${court.pricePerHour.toInt()}/hr';
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push(
                          AppConstants.routeCourtDetail,
                          extra: court,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Icon(
                                sportIconForName(sportType),
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    court.name,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final venue = widget.venue;
    final sports = _sportTypes;
    final lowestPricePerHour = _lowestPricePerHour;

    return Scaffold(
      backgroundColor: AppColors.surface,
      bottomNavigationBar: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: Container(
          color: AppColors.surface,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: sports.isEmpty ? null : _openSportTypePicker,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(Icons.sports_tennis_rounded, size: 18),
                  label: const Text(
                    'Proceed: choose a sport type',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 340,
            child: Stack(
              fit: StackFit.expand,
              children: [
                StorageImage(
                  storagePath: venue.imageUrl,
                  bucketName: StadiumRepository.imageBucket,
                  width: double.infinity,
                  height: 340,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.zero,
                  placeholder: Container(
                    color: AppColors.divider,
                    child: const Icon(
                      Icons.stadium_rounded,
                      size: 70,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.4],
                      colors: [Colors.black45, Colors.transparent],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 290)),
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  venue.name,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    height: 1.1,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              if (lowestPricePerHour != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.divider.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.currency_rupee_rounded,
                                        size: 14,
                                        color: AppColors.textPrimary,
                                      ),
                                      Text(
                                        '$lowestPricePerHour onwards',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${venue.address}, ${venue.city}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildSkeletalStat('Courts', '${_venueCourts.length}'),
                              Container(height: 30, width: 1, color: AppColors.divider),
                              _buildSkeletalStat('Sports', '${sports.length}'),
                              Container(height: 30, width: 1, color: AppColors.divider),
                              _buildSkeletalStat('City', venue.city),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const DetailSectionTitle(title: 'About Venue'),
                          const SizedBox(height: 10),
                          Text(
                            venue.description.isEmpty
                                ? 'No description provided for this venue yet.'
                                : venue.description,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13.5,
                              color: AppColors.textSecondary,
                              height: 1.65,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const DetailSectionTitle(title: 'Amenities'),
                          const SizedBox(height: 10),
                          if (venue.amenities.isEmpty)
                            const Text(
                              'No amenities listed yet.',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: venue.amenities
                                  .map(
                                    (amenity) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.divider),
                                      ),
                                      child: Text(
                                        amenity,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          const SizedBox(height: 24),
                          const DetailSectionTitle(title: 'Sport Types'),
                          const SizedBox(height: 10),
                          if (sports.isEmpty)
                            const Text(
                              'No sport types available for this venue.',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: sports
                                  .map(
                                    (sport) => ActionChip(
                                      avatar: Icon(
                                        sportIconForName(sport),
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      label: Text(
                                        sport,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      backgroundColor: AppColors.surface,
                                      side: const BorderSide(color: AppColors.divider),
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      onPressed: () => _openCourtsForSport(sport),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: _CircleBtn(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletalStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:turf_booking/app/theme/app_colors.dart';
import 'package:turf_booking/app/constants/app_constants.dart';

class StadiumModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final bool isActive;
  final int courtsCount;

  const StadiumModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.isActive,
    required this.courtsCount,
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
  ),
  StadiumModel(
    id: '2',
    name: 'Turf Zone',
    address: '45, Koramangala',
    city: 'Bengaluru',
    isActive: true,
    courtsCount: 2,
  ),
  StadiumModel(
    id: '3',
    name: 'PlayField Hub',
    address: '8, Whitefield',
    city: 'Bengaluru',
    isActive: false,
    courtsCount: 1,
  ),
];

class OwnerMyStadiumsScreen extends StatelessWidget {
  const OwnerMyStadiumsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Stadiums'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () {
                // TODO: navigate to add stadium screen
              },
              icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
              label: const Text(
                'Add',
                style: TextStyle(
                  color: AppColors.primary,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _mockStadiums.isEmpty
          ? _buildEmpty()
          : ListView.separated(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              itemCount: _mockStadiums.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
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
            'Tap Add to create your first stadium',
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

class _StadiumCard extends StatelessWidget {
  final StadiumModel stadium;
  const _StadiumCard({required this.stadium});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    stadium.name,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: stadium.isActive
                        ? AppColors.badgeBg
                        : AppColors.chipUnselected,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    stadium.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: stadium.isActive
                          ? AppColors.badgeText
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${stadium.address}, ${stadium.city}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.textSecondary,
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
                GestureDetector(
                  onTap: () {
                    // TODO: navigate to stadium detail/edit
                  },
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}

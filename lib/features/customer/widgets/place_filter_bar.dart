import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class PlaceFilterBar extends StatelessWidget {
  final List<String> places;
  final List<String> selectedPlaces;
  final ValueChanged<String> onToggle;

  const PlaceFilterBar({
    super.key,
    required this.places,
    required this.selectedPlaces,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: places.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final allSelected = selectedPlaces.isEmpty;
            return _FilterChip(
              label: 'All',
              isSelected: allSelected,
              onTap: () {
                // Deselect everything = show all
                for (final p in List.from(selectedPlaces)) {
                  onToggle(p);
                }
              },
            );
          }
          final place = places[index - 1];
          return _FilterChip(
            label: place,
            isSelected: selectedPlaces.contains(place),
            onTap: () => onToggle(place),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class CustomerFloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const CustomerFloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        child: Material(
          color: Colors.transparent,
          elevation: 12,
          shadowColor: Colors.black.withOpacity(0.14),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.sports_tennis_rounded,
                  isSelected: selectedIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: Icons.calendar_month_rounded,
                  isSelected: selectedIndex == 1,
                  onTap: () => onTap(1),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  isSelected: selectedIndex == 2,
                  onTap: () => onTap(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isSelected
        ? AppColors.textPrimary
        : AppColors.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 1.25,
              ),
            ),
            child: Icon(icon, size: 19, color: iconColor),
          ),
        ),
      ),
    );
  }
}

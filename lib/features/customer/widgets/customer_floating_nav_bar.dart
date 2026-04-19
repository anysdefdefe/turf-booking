import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../data/models/booking_cart_item.dart';
import '../data/repositories/customer_cart_repository.dart';

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
    final cartRepo = CustomerCartRepository.instance;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        child: Material(
          color: Colors.transparent,
          elevation: 12,
          shadowColor: Colors.black.withValues(alpha: 0.14),
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
                ValueListenableBuilder<List<BookingCartItem>>(
                  valueListenable: cartRepo.cartItemsNotifier,
                  builder: (context, items, _) => _NavItem(
                    icon: Icons.shopping_bag_outlined,
                    isSelected: selectedIndex == 1,
                    onTap: () => onTap(1),
                    badgeCount: items.length,
                  ),
                ),
                _NavItem(
                  icon: Icons.event_note_rounded,
                  isSelected: selectedIndex == 2,
                  onTap: () => onTap(2),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  isSelected: selectedIndex == 3,
                  onTap: () => onTap(3),
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
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isSelected ? AppColors.textPrimary : Colors.transparent,
                    width: 1.25,
                  ),
                ),
                child: Icon(icon, size: 19, color: iconColor),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -2,
                  right: -4,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

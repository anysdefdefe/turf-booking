import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../data/models/booking_cart_item.dart';
import '../data/repositories/customer_cart_repository.dart';

class CustomerBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const CustomerBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cartRepo = CustomerCartRepository.instance;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.sports_tennis_rounded,
                label: 'Explore',
                isSelected: selectedIndex == 0,
                onTap: () => onTap(0),
              ),
              ValueListenableBuilder<List<BookingCartItem>>(
                valueListenable: cartRepo.cartItemsNotifier,
                builder: (context, items, _) => _NavItem(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Cart',
                  isSelected: selectedIndex == 1,
                  onTap: () => onTap(1),
                  badgeCount: items.length,
                ),
              ),
              _NavItem(
                icon: Icons.event_note_rounded,
                label: 'Bookings',
                isSelected: selectedIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                isSelected: selectedIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (badgeCount > 0)
              Positioned(
                top: -2,
                right: -6,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

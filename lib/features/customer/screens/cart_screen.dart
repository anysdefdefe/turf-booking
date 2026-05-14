import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants/app_constants.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/models/booking_args.dart';
import '../data/models/booking_cart_item.dart';
import '../data/repositories/customer_cart_repository.dart';
import '../widgets/customer_bottom_nav_bar.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CustomerCartRepository _cartRepo = CustomerCartRepository.instance;

  void _onNavTap(int index) {
    if (index == 1) {
      return;
    }
    if (index == 0) {
      context.go('/customer/home');
      return;
    }
    if (index == 2) {
      context.go('/customer/my-bookings');
      return;
    }
    if (index == 3) {
      context.go('/customer/profile');
    }
  }

  void _removeItem(BookingCartItem item) {
    _cartRepo.removeItem(item.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.court.name} removed from cart.')),
    );
  }

  void _proceedToBooking(List<BookingCartItem> items) {
    if (items.isEmpty) {
      return;
    }
    context.push(
      AppConstants.routeBookingConfirm,
      extra: BookingArgs(cartItems: items),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          'Booking Cart',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: cs.onSurface,
          ),
        ),
        centerTitle: false,
        backgroundColor: cs.surface,
        elevation: 0,
      ),
      bottomNavigationBar: CustomerBottomNavBar(
        selectedIndex: 1,
        onTap: _onNavTap,
      ),
      body: ValueListenableBuilder<List<BookingCartItem>>(
        valueListenable: _cartRepo.cartItemsNotifier,
        builder: (context, items, _) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'Your cart is empty',
              subtitle: 'Add a court slot to continue booking',
              icon: Icons.shopping_bag_outlined,
            );
          }

          final totalAmount = items.fold<double>(
            0,
            (sum, item) => sum + item.totalAmount,
          );
          final totalSlots = items.fold<int>(
            0,
            (sum, item) => sum + item.durationHours,
          );

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 14),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _CartItemCard(
                      item: item,
                      onRemove: () => _removeItem(item),
                      context: context,
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  border: Border(top: BorderSide(color: cs.outline)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          '$totalSlots slot${totalSlots == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '₹${totalAmount.toInt()}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _proceedToBooking(items),
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        icon: const Icon(
                          Icons.event_available_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Proceed to Booking',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final BookingCartItem item;
  final VoidCallback onRemove;
  final BuildContext context;

  const _CartItemCard({
    required this.item,
    required this.onRemove,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateText = _formatDate(item.date);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.court.name,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Remove',
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
          Text(
            item.court.stadiumName,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${item.court.place}, ${item.court.city}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$dateText • ${item.durationHours} slot${item.durationHours == 1 ? '' : 's'}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sports: ${item.sportsLabel}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: item.slots
                .map(
                  (slot) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.outline),
                    ),
                    child: Text(
                      slot,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

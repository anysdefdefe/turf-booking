import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_provider.dart';

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;

  const AdminUserDetailScreen({super.key, required this.user});

  @override
  ConsumerState<AdminUserDetailScreen> createState() =>
      _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> {
  late Map<String, dynamic> _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = _user['full_name'] ?? 'Unknown';
    final email = _user['email'] ?? '';
    final phone = _user['phone'] ?? 'Not provided';
    final isOwner = _user['is_owner'] == true;
    final isApproved = _user['is_approved'] == true;
    final isBlocked = _user['is_blocked'] == true;
    final isAdmin = _user['is_admin'] == true;
    final joinedDate = _formatDate(_user['created_at']);

    // Fetch this user's bookings
    final bookingsAsync = ref.watch(allBookingsProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('User Details'),
        actions: [
          // Block/Unblock action in appbar
          IconButton(
            icon: Icon(
              isBlocked ? Icons.lock_open : Icons.block,
              color: isBlocked ? Colors.green : cs.error,
            ),
            tooltip: isBlocked ? 'Unblock' : 'Block',
            onPressed: () =>
                isBlocked ? _handleUnblock(context) : _handleBlock(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                children: [
                  // Avatar + name
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: isBlocked
                            ? cs.errorContainer
                            : cs.primaryContainer,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isBlocked ? cs.error : cs.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Status badges
                            Wrap(
                              spacing: 6,
                              children: [
                                _badge(
                                  isOwner ? 'Owner' : 'Customer',
                                  isOwner ? Colors.blue : Colors.grey,
                                ),
                                if (isOwner)
                                  _badge(
                                    isApproved ? 'Approved' : 'Pending',
                                    isApproved ? Colors.green : Colors.orange,
                                  ),
                                if (isAdmin) _badge('Admin', Colors.purple),
                                if (isBlocked) _badge('Blocked', Colors.red),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  // Details
                  _detailRow(Icons.phone_outlined, 'Phone', phone),
                  const SizedBox(height: 10),
                  _detailRow(
                    Icons.calendar_today_outlined,
                    'Joined',
                    joinedDate,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Role Change Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚙️ Admin Actions',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),

                  // Change Role Button
                  if (!isAdmin) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.swap_horiz),
                        label: Text(
                          isOwner ? 'Change to Customer' : 'Promote to Owner',
                        ),
                        onPressed: () => _handleRoleChange(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Block/Unblock Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: Icon(isBlocked ? Icons.lock_open : Icons.block),
                      label: Text(isBlocked ? 'Unblock User' : 'Block User'),
                      onPressed: () => isBlocked
                          ? _handleUnblock(context)
                          : _handleBlock(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: isBlocked ? Colors.green : cs.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Booking History
            const Text(
              '📅 Booking History',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            bookingsAsync.when(
              loading: () =>
                  Center(child: CircularProgressIndicator(color: cs.primary)),
              error: (e, _) => Text(
                'Could not load bookings',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              data: (bookings) {
                // Filter bookings for this user
                final userBookings = bookings
                    .where((b) => b['customer_id'] == _user['id'])
                    .toList();

                if (userBookings.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Center(
                      child: Text(
                        'No bookings yet',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ),
                  );
                }

                // Summary
                final totalSpent = userBookings.fold<double>(
                  0,
                  (sum, b) =>
                      sum + ((b['total_amount'] ?? 0) as num).toDouble(),
                );

                return Column(
                  children: [
                    // Summary card
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _summaryItem(
                            '${userBookings.length}',
                            'Total Bookings',
                            cs,
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: cs.outlineVariant,
                          ),
                          _summaryItem(
                            '₹${totalSpent.toStringAsFixed(0)}',
                            'Total Spent',
                            cs,
                          ),
                        ],
                      ),
                    ),

                    // Bookings list
                    ...userBookings.map((booking) {
                      final status = booking['status'] ?? 'unknown';
                      Color statusColor;
                      switch (status.toLowerCase()) {
                        case 'confirmed':
                          statusColor = Colors.green;
                          break;
                        case 'cancelled':
                          statusColor = Colors.red;
                          break;
                        default:
                          statusColor = Colors.orange;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.book_online,
                                color: statusColor,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking['booking_date'] ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${booking['start_time']} - ${booking['end_time']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${booking['total_amount']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _summaryItem(String value, String label, ColorScheme cs) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cs.primary,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
      ],
    );
  }

  Future<void> _handleRoleChange(BuildContext context) async {
    final isOwner = _user['is_owner'] == true;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Role'),
        content: Text(
          isOwner
              ? 'Change ${_user['full_name']} from Owner to Customer?'
              : 'Promote ${_user['full_name']} to Owner?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.changeUserRole(_user['id'], isOwner: !isOwner);

      setState(() {
        _user = {..._user, 'is_owner': !isOwner};
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOwner ? 'Changed to Customer ✅' : 'Promoted to Owner ✅',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleBlock(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text('Block ${_user['full_name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.blockUser(_user['id']);
      setState(() => _user = {..._user, 'is_blocked': true});
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User blocked ❌')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleUnblock(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text('Unblock ${_user['full_name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.unblockUser(_user['id']);
      setState(() => _user = {..._user, 'is_blocked': false});
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User unblocked ✅')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

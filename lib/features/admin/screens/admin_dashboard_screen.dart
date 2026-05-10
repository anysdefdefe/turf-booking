import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_controller.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../app/constants/app_constants.dart';
import '../providers/admin_provider.dart';
import '../widgets/stat_card.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String _range = '24h'; // '24h', '7d', or 'all'

  /// Format a [DateTime] to a readable 12-hour time string (e.g. "9:00 AM").
  String _formatDateTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $suffix';
  }

  /// Fallback: format a raw "HH:mm:ss" or ISO time string.
  String _formatTimeStr(String raw) {
    final dt = DateTime.tryParse('2000-01-01 $raw');
    if (dt == null) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return _formatDateTime(parsed);
      return raw;
    }
    return _formatDateTime(dt);
  }

  /// Calculate total hours from slots or start/end time.
  int _calculateTotalHours(Map<String, dynamic> booking) {
    final slots = booking['slots'];
    if (slots is List && slots.isNotEmpty) {
      int total = 0;
      for (var s in slots) {
        final st = s['start_time']?.toString() ?? '';
        final et = s['end_time']?.toString() ?? '';
        if (st.isNotEmpty && et.isNotEmpty) {
          try {
            final startDt = DateTime.tryParse('2000-01-01 $st');
            final endDt = DateTime.tryParse('2000-01-01 $et');
            if (startDt != null && endDt != null) {
              total += endDt.difference(startDt).inHours;
            }
          } catch (_) {}
        }
      }
      return total;
    }

    // Fallback: use start/end time
    final st = booking['start_time']?.toString() ?? '';
    final et = booking['end_time']?.toString() ?? '';
    if (st.isNotEmpty && et.isNotEmpty) {
      try {
        final startDt = DateTime.tryParse('2000-01-01 $st');
        final endDt = DateTime.tryParse('2000-01-01 $et');
        if (startDt != null && endDt != null) {
          return endDt.difference(startDt).inHours;
        }
      } catch (_) {}
    }
    return 0;
  }

  List<double> _computeSeries(List<Map<String, dynamic>> bookings) {
    if (_range == '24h') {
      final last = bookings.take(24).toList();
      return last.reversed.map<double>((b) => (b['total_amount'] ?? 0).toDouble()).toList();
    } else if (_range == '7d') {
      final now = DateTime.now();
      final List<double> buckets = List.filled(7, 0.0);
      for (var b in bookings) {
        final bd = b['booking_date']?.toString();
        if (bd == null) continue;
        final dt = DateTime.tryParse(bd);
        if (dt == null) continue;
        final diff = now.difference(DateTime(dt.year, dt.month, dt.day)).inDays;
        if (diff >= 0 && diff < 7) {
          buckets[6 - diff] += (b['total_amount'] ?? 0).toDouble();
        }
      }
      return buckets;
    } else {
      final now = DateTime.now();
      final List<double> buckets = List.filled(12, 0.0);
      for (var b in bookings) {
        final bd = b['booking_date']?.toString();
        if (bd == null) continue;
        final dt = DateTime.tryParse(bd);
        if (dt == null) continue;
        final monthsDiff = (now.year - dt.year) * 12 + (now.month - dt.month);
        if (monthsDiff >= 0 && monthsDiff < 12) {
          buckets[11 - monthsDiff] += (b['total_amount'] ?? 0).toDouble();
        }
      }
      return buckets;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final bookingsAsync = ref.watch(allBookingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF4CAF50),
          onRefresh: () async {
            ref.refresh(dashboardStatsProvider);
            ref.refresh(allBookingsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Admin dashboard',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Here's your system overview",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                      ),
                    ),
                    // Profile menu (enhanced bottom sheet)
                    Builder(builder: (context) {
                      final userAsync = ref.watch(authStateProvider);
                      return userAsync.when(
                        data: (user) {
                          final avatar = user?.avatarUrl;
                          final display = user?.fullName ?? user?.email ?? 'Admin';
                          return InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: () => _showProfileMenu(context, ref, user),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFF4CAF50),
                              backgroundImage: avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
                              child: avatar == null || avatar.isEmpty
                                  ? Text(display.isNotEmpty ? display[0].toUpperCase() : 'A', style: const TextStyle(color: Colors.white))
                                  : null,
                            ),
                          );
                        },
                        loading: () => const CircleAvatar(backgroundColor: Color(0xFF4CAF50), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
                        error: (_, __) => const CircleAvatar(backgroundColor: Color(0xFF4CAF50), child: Icon(Icons.person, color: Colors.white)),
                      );
                    }),
                  ],
                ),

                const SizedBox(height: 24),

                // Stats Row (horizontally scrollable)
                statsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                  ),
                  error: (e, _) => Center(
                    child: Column(
                      children: [
                        Text('Error: $e', style: const TextStyle(color: Colors.red)),
                        ElevatedButton(
                          onPressed: () => ref.refresh(dashboardStatsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (stats) {
                    // Build horizontally scrollable stat cards (thin scrollbar)
                    final controller = ScrollController();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 110,
                          child: RawScrollbar(
                            controller: controller,
                            thumbColor: const Color(0xFF4CAF50).withOpacity(0.6),
                            radius: const Radius.circular(6),
                            thickness: 4,
                            child: SingleChildScrollView(
                              controller: controller,
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  const SizedBox(width: 4),
                                  _StatCardLarge(
                                    width: 240,
                                    height: 96,
                                    title: 'Total Revenue',
                                    value: '₹${stats['totalRevenue'].toStringAsFixed(0)}',
                                    icon: Icons.attach_money_rounded,
                                    iconColor: const Color(0xFFEF5350),
                                  ),
                                  const SizedBox(width: 12),
                                  _StatCardLarge(
                                    width: 240,
                                    height: 96,
                                    title: 'Total Transactions',
                                    value: '${stats['totalBookings']}',
                                    icon: Icons.receipt_long_rounded,
                                    iconColor: const Color(0xFF66BB6A),
                                  ),
                                  const SizedBox(width: 12),
                                  _StatCardLarge(
                                    width: 240,
                                    height: 96,
                                    title: 'Total Users',
                                    value: '${stats['totalUsers']}',
                                    icon: Icons.people_rounded,
                                    iconColor: const Color(0xFF5C6BC0),
                                  ),
                                  const SizedBox(width: 12),
                                  _StatCardLarge(
                                    width: 240,
                                    height: 96,
                                    title: 'Total Venues',
                                    value: '${stats['totalVenues']}',
                                    icon: Icons.location_city_rounded,
                                    iconColor: const Color(0xFFAB47BC),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        if (stats['pendingApprovals'] > 0)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3CD),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFFE69C)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.pending_actions, color: Color(0xFF856404), size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${stats['pendingApprovals']} owner application(s) waiting for your approval!',
                                    style: const TextStyle(color: Color(0xFF856404), fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Revenue Chart + Range Toggle
                const Text('Revenue', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _CustomChoiceChip(label: 'Last 24 hours', selected: _range == '24h', onSelected: (v) => setState(() => _range = '24h')),
                      const SizedBox(width: 8),
                      _CustomChoiceChip(label: 'Last 7 days', selected: _range == '7d', onSelected: (v) => setState(() => _range = '7d')),
                      const SizedBox(width: 8),
                      _CustomChoiceChip(label: 'All time', selected: _range == 'all', onSelected: (v) => setState(() => _range = 'all')),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                bookingsAsync.when(
                  loading: () => const SizedBox(height: 140, child: Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))),
                  error: (e, _) => Text('Could not load bookings', style: TextStyle(color: Colors.grey[500])),
                  data: (bookings) {
                    final series = _computeSeries(bookings.cast<Map<String, dynamic>>());
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 140, child: _EnhancedSparklineChart(data: series)),
                          const SizedBox(height: 12),
                          LayoutBuilder(builder: (context, constraints) {
                            final left = Text(
                              _range == '24h' ? 'Last 24 hours' : _range == '7d' ? 'Last 7 days' : 'All time',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF666666)),
                            );
                            final right = Text(
                              'Total: ₹${bookings.fold<double>(0, (p, e) => p + ((e['total_amount'] ?? 0).toDouble())).toStringAsFixed(0)}',
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF4CAF50)),
                            );

                            if (constraints.maxWidth < 220) {
                              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [left, const SizedBox(height: 6), Align(alignment: Alignment.centerRight, child: right)]);
                            }

                            return Row(children: [Expanded(child: left), const SizedBox(width: 8), Flexible(fit: FlexFit.tight, child: right)]);
                          }),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Recent Bookings Section
                const Text('Recent Bookings', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 12),

                bookingsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50))),
                  error: (e, _) => Text('Could not load bookings', style: TextStyle(color: Colors.grey[500])),
                  data: (bookings) {
                    if (bookings.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: const Center(child: Text('No bookings yet', style: TextStyle(color: Colors.grey))),
                      );
                    }

                    final recent = bookings.take(5).toList();

                    return Column(
                      children: recent.map((booking) {
                        final status = booking['status'] ?? 'unknown';
                        final paymentStatus = booking['payment_status'] ?? 'unknown';
                        final userName = booking['users']?['full_name'] ?? 'Unknown User';
                        final totalHours = _calculateTotalHours(booking);

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
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                          ]),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Icon(Icons.book_online, color: statusColor, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(userName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                      Text('${booking['booking_date']} • ₹${booking['total_amount']}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                    ]),
                                  ),
                                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                      child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(paymentStatus, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                                  ]),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Slots display - show each individual slot
                              Builder(builder: (_) {
                                final slots = booking['slots'];
                                if (slots is List && slots.isNotEmpty) {
                                  return Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: slots.map<Widget>((s) {
                                      // Use ONLY slot times, not booking times
                                      final st = s['start_time']?.toString() ?? '';
                                      final et = s['end_time']?.toString() ?? '';
                                      if (st.isEmpty || et.isEmpty) return const SizedBox.shrink();
                                      
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0FFF4),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.2)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.access_time_outlined, size: 12, color: Color(0xFF4CAF50)),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${_formatTimeStr(st)} – ${_formatTimeStr(et)}',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  );
                                }

                                // Fallback: if no slots, show single booking range
                                final st = booking['start_time']?.toString() ?? '';
                                final et = booking['end_time']?.toString() ?? '';
                                if (st.isNotEmpty && et.isNotEmpty) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FFF4),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.access_time_outlined, size: 12, color: Color(0xFF4CAF50)),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${_formatTimeStr(st)} – ${_formatTimeStr(et)}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }),
                              const SizedBox(height: 8),
                              // Total hours
                              Row(
                                children: [
                                  Icon(Icons.schedule, size: 13, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Total: $totalHours hour${totalHours != 1 ? 's' : ''}',
                                    style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  void _showProfileMenu(BuildContext context, WidgetRef ref, dynamic user) {
    final name = user?.fullName ?? user?.email ?? 'Admin';
    final avatar = user?.avatarUrl as String?;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ProfileMenu(
        name: name,
        email: user?.email ?? '',
        avatarUrl: avatar,
        onLogout: () async {
          Navigator.pop(context);
          await ref.read(authControllerProvider.notifier).signOut();
          if (mounted) context.go(AppConstants.routeLogin);
        },
        onSwitch: () {
          Navigator.pop(context);
          context.go(AppConstants.routeModeSelection);
        },
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF999999), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  final String name;
  final String email;
  final String? avatarUrl;
  final VoidCallback onLogout;
  final VoidCallback onSwitch;

  const _ProfileMenu({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.onLogout,
    required this.onSwitch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            // Avatar + name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFF4CAF50),
                    backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty ? NetworkImage(avatarUrl!) : null,
                    child: avatarUrl == null || avatarUrl!.isEmpty ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'A', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)) : null,
                  ),
                  const SizedBox(height: 12),
                  Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF4CAF50)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: onSwitch,
                      icon: const Icon(Icons.swap_horiz, color: Color(0xFF4CAF50)),
                      label: const Text('Switch Role', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout_rounded, color: Colors.red),
                      label: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDestructive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : const Color(0xFF4CAF50);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnhancedStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Gradient gradient;

  const _EnhancedStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatCardLarge extends StatelessWidget {
  final double width;
  final double height;
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatCardLarge({
    required this.width,
    required this.height,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF888888), fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)))),
                    const SizedBox(width: 6),
                    // placeholder percent change
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.withOpacity(0.12))),
                      child: Row(
                        children: const [
                          Icon(Icons.trending_up, size: 12, color: Color(0xFF2E7D32)),
                          SizedBox(width: 4),
                          Text('16%', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _CustomChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected(true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? const Color(0xFF4CAF50) : Colors.grey[300]!, width: 1.5),
          boxShadow: selected
              ? [BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? const Color(0xFF4CAF50) : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}

class _EnhancedSparklineChart extends StatelessWidget {
  final List<double> data;

  const _EnhancedSparklineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _EnhancedSparklinePainter(data, const Color(0xFF2196F3)),
      size: const Size(double.infinity, double.infinity),
    );
  }
}

class _EnhancedSparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _EnhancedSparklinePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final max = data.reduce((a, b) => a > b ? a : b);
    final min = data.reduce((a, b) => a < b ? a : b);
    final range = (max - min) == 0 ? 1 : (max - min);

    final stepX = size.width / (data.length - 1).clamp(1, double.infinity);

    // Draw gradient fill
    final fillPath = Path();
    fillPath.moveTo(0, size.height);
    for (var i = 0; i < data.length; i++) {
      final x = stepX * i;
      final y = size.height - ((data[i] - min) / range) * size.height;
      fillPath.lineTo(x, y);
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.05)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, gradientPaint);

    // Draw line
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = stepX * i;
      final y = size.height - ((data[i] - min) / range) * size.height;
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    canvas.drawPath(path, linePaint);

    // Draw dots at points
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var i = 0; i < data.length; i++) {
      final x = stepX * i;
      final y = size.height - ((data[i] - min) / range) * size.height;
      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
    }

    // Draw background dots
    final bgDotPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < data.length; i++) {
      final x = stepX * i;
      final y = size.height - ((data[i] - min) / range) * size.height;
      canvas.drawCircle(Offset(x, y), 5.5, bgDotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Legacy sparkline chart class (kept for compatibility if needed)
class _SparklineChart extends StatelessWidget {
  final List<double> data;

  const _SparklineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(data, Theme.of(context).colorScheme.primary),
      size: const Size(double.infinity, double.infinity),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _SparklinePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..isAntiAlias = true;

    if (data.isEmpty) return;
    final max = data.reduce((a, b) => a > b ? a : b);
    final min = data.reduce((a, b) => a < b ? a : b);
    final range = (max - min) == 0 ? 1 : (max - min);

    final stepX = size.width / (data.length - 1).clamp(1, double.infinity);
    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = stepX * i;
      final y = size.height - ((data[i] - min) / range) * size.height;
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
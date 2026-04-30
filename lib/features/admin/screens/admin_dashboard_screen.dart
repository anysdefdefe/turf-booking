import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_controller.dart';
import '../../../app/constants/app_constants.dart';
import '../providers/admin_provider.dart';
import '../widgets/stat_card.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String _range = '24h'; // '24h' or '7d'

  List<double> _computeSeries(List<Map<String, dynamic>> bookings) {
    // Simple series: last 7 days totals (or last 24 entries)
    if (_range == '24h') {
      // use the last 24 bookings' amounts (fallback if not enough)
      final last = bookings.take(24).toList();
      return last.reversed.map<double>((b) => (b['total_amount'] ?? 0).toDouble()).toList();
    }
    // 7 day aggregation: buckets by booking_date
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
                    Column(
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
                    // Profile menu
                    PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'logout') {
                          await ref.read(authControllerProvider.notifier).signOut();
                          if (mounted) context.go(AppConstants.routeLogin);
                        } else if (v == 'switch') {
                          if (mounted) context.go(AppConstants.routeModeSelection);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'switch', child: Text('Switch role')),
                        PopupMenuItem(value: 'logout', child: Text('Logout')),
                      ],
                      child: const CircleAvatar(
                        backgroundColor: Color(0xFF4CAF50),
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                        ),
                      ),
                    ),
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
                  data: (stats) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 120,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const SizedBox(width: 4),
                              StatCard(
                                label: 'Total Users',
                                value: '${stats['totalUsers']}',
                                icon: Icons.people,
                                color: const Color(0xFF4CAF50),
                              ),
                              const SizedBox(width: 12),
                              StatCard(
                                label: 'Total Venues',
                                value: '${stats['totalVenues']}',
                                icon: Icons.stadium,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 12),
                              StatCard(
                                label: 'Total Bookings',
                                value: '${stats['totalBookings']}',
                                icon: Icons.calendar_today,
                                color: Colors.purple,
                              ),
                              const SizedBox(width: 12),
                              StatCard(
                                label: 'Total Revenue',
                                value: '₹${stats['totalRevenue'].toStringAsFixed(0)}',
                                icon: Icons.currency_rupee,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 12),
                              // extra spacer
                              const SizedBox(width: 8),
                            ],
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
                  ),
                ),

                const SizedBox(height: 20),

                // Revenue Chart + Range Toggle
                const Text('Revenue', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ChoiceChip(label: const Text('Last 24 hours'), selected: _range == '24h', onSelected: (v) => setState(() => _range = '24h')),
                    const SizedBox(width: 8),
                    ChoiceChip(label: const Text('Last 7 days'), selected: _range == '7d', onSelected: (v) => setState(() => _range = '7d')),
                  ],
                ),
                const SizedBox(height: 12),

                bookingsAsync.when(
                  loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))),
                  error: (e, _) => Text('Could not load bookings', style: TextStyle(color: Colors.grey[500])),
                  data: (bookings) {
                    final series = _computeSeries(bookings.cast<Map<String, dynamic>>());
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          SizedBox(height: 120, child: _SparklineChart(data: series)),
                          const SizedBox(height: 8),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(_range == '24h' ? 'Last 24 hours' : 'Last 7 days', style: TextStyle(color: Colors.grey[600])),
                            Text('Total: ₹${bookings.fold<double>(0, (p, e) => p + ((e['total_amount'] ?? 0).toDouble())).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ]),
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
                          child: Row(
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
}

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
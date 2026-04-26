import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_provider.dart';
import '../widgets/stat_card.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                          'Welcome, Admin 👋',
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
                    const CircleAvatar(
                      backgroundColor: Color(0xFF4CAF50),
                      child: Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Stats Grid
                statsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF4CAF50)),
                  ),
                  error: (e, _) => Center(
                    child: Column(
                      children: [
                        Text('Error: $e',
                            style:
                                const TextStyle(color: Colors.red)),
                        ElevatedButton(
                          onPressed: () =>
                              ref.refresh(dashboardStatsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (stats) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stat Cards
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.4,
                        children: [
                          StatCard(
                            label: 'Total Users',
                            value: '${stats['totalUsers']}',
                            icon: Icons.people,
                            color: const Color(0xFF4CAF50),
                          ),
                          StatCard(
                            label: 'Total Venues',
                            value: '${stats['totalVenues']}',
                            icon: Icons.stadium,
                            color: Colors.blue,
                          ),
                          StatCard(
                            label: 'Total Bookings',
                            value: '${stats['totalBookings']}',
                            icon: Icons.calendar_today,
                            color: Colors.purple,
                          ),
                          StatCard(
                            label: 'Total Revenue',
                            value:
                                '₹${stats['totalRevenue'].toStringAsFixed(0)}',
                            icon: Icons.currency_rupee,
                            color: Colors.orange,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Pending Approvals Banner
                      if (stats['pendingApprovals'] > 0)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3CD),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFFE69C),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.pending_actions,
                                color: Color(0xFF856404),
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${stats['pendingApprovals']} owner application(s) waiting for your approval!',
                                  style: const TextStyle(
                                    color: Color(0xFF856404),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Recent Bookings Section
                const Text(
                  'Recent Bookings',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),

                bookingsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF4CAF50)),
                  ),
                  error: (e, _) => Text(
                    'Could not load bookings',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  data: (bookings) {
                    if (bookings.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'No bookings yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    // Show only last 5 bookings
                    final recent = bookings.take(5).toList();

                    return Column(
                      children: recent.map((booking) {
                        final status =
                            booking['status'] ?? 'unknown';
                        final paymentStatus =
                            booking['payment_status'] ?? 'unknown';
                        final userName =
                            booking['users']?['full_name'] ??
                                'Unknown User';

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
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: statusColor
                                      .withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.book_online,
                                  color: statusColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '${booking['booking_date']} • ₹${booking['total_amount']}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusColor
                                          .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(6),
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
                                  const SizedBox(height: 4),
                                  Text(
                                    paymentStatus,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[400],
                                    ),
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
}
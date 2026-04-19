import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/quick_action_tile.dart';

class AdminDashboardScreen extends ConsumerWidget {
  final VoidCallback onGoToApprovals;
  final VoidCallback onGoToVenues;
  final VoidCallback onGoToUsers;

  const AdminDashboardScreen({
    super.key,
    required this.onGoToApprovals,
    required this.onGoToVenues,
    required this.onGoToUsers,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF4CAF50),
          onRefresh: () async => ref.refresh(dashboardStatsProvider),
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

                // Stats
                statsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Column(
                      children: [
                        Text('Error: $e',
                            style: const TextStyle(color: Colors.red)),
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
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.6,
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
                            value: '₹${stats['totalRevenue'].toStringAsFixed(0)}',
                            icon: Icons.currency_rupee,
                            color: Colors.orange,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 14),

                      QuickActionTile(
                        icon: Icons.pending_actions,
                        title: 'Pending Approvals',
                        subtitle: 'Review new stadium owner requests',
                        badgeCount: stats['pendingApprovals'],
                        onTap: onGoToApprovals,
                      ),
                      QuickActionTile(
                        icon: Icons.stadium,
                        title: 'Manage Venues',
                        subtitle: 'View and control all stadiums',
                        onTap: onGoToVenues,
                      ),
                      QuickActionTile(
                        icon: Icons.people,
                        title: 'Manage Users',
                        subtitle: 'View and control all customers',
                        onTap: onGoToUsers,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
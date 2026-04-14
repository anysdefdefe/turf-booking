import 'package:flutter/material.dart';
import '../data/models/admin_stats_model.dart';
import '../data/repositories/admin_repository.dart';
import '../widgets/stat_card.dart';
import '../widgets/quick_action_tile.dart';

class AdminDashboardScreen extends StatefulWidget {
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
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
 final AdminRepository _repo = AdminRepository.instance;
  AdminStatsModel? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _repo.getAdminStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF4CAF50),
          onRefresh: _loadStats,
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
                        Text(
                          'Welcome, Admin 👋',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
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
                      child: Icon(Icons.admin_panel_settings, color: Colors.white),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Stats Grid
                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
                else if (_stats != null) ...[
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.1,
                    children: [
                      StatCard(
                        label: 'Total Stadiums',
                        value: '${_stats!.totalStadiums}',
                        icon: Icons.stadium,
                        color: const Color(0xFF4CAF50),
                      ),
                      StatCard(
                        label: 'Total Bookings',
                        value: '${_stats!.totalBookings}',
                        icon: Icons.calendar_today,
                        color: Colors.blue,
                      ),
                      StatCard(
                        label: 'Total Revenue',
                        value: '₹${_stats!.totalRevenue.toStringAsFixed(0)}',
                        icon: Icons.currency_rupee,
                        color: Colors.purple,
                      ),
                      StatCard(
                        label: 'Commission Earned',
                        value: '₹${_stats!.commissionEarned.toStringAsFixed(0)}',
                        icon: Icons.percent,
                        color: Colors.orange,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Quick Actions
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
                    badgeCount: _stats!.pendingApprovals,
                    onTap: widget.onGoToApprovals,
                  ),
                  QuickActionTile(
                    icon: Icons.stadium,
                    title: 'Manage Venues',
                    subtitle: 'View and control all stadiums',
                    onTap: widget.onGoToVenues,
                  ),
                  QuickActionTile(
                    icon: Icons.people,
                    title: 'Manage Users',
                    subtitle: 'View and control all customers',
                    onTap: widget.onGoToUsers,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
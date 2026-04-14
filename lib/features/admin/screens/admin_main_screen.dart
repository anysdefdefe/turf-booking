import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';
import 'admin_approvals_screen.dart';
import 'admin_venues_screen.dart';
import 'admin_users_screen.dart';
import 'admin_settings_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  void _goToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      AdminDashboardScreen(
        onGoToApprovals: () => _goToTab(1),
        onGoToVenues: () => _goToTab(2),
        onGoToUsers: () => _goToTab(3),
      ),
      const AdminApprovalsScreen(),
      const AdminVenuesScreen(),
      const AdminUsersScreen(),
      const AdminSettingsScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.pending_actions), label: 'Approvals'),
          BottomNavigationBarItem(icon: Icon(Icons.stadium), label: 'Venues'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
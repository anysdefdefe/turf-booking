import 'package:flutter/material.dart';

import '../../features/home/screens/court_detail_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/splash_screen.dart';
import 'app_constants.dart';
import '../../../features/owner/screens/pending_approval_screen.dart';
import '../../../features/owner/screens/owner_dashboard_screen.dart';

/// Navigation router for the application.
class AppRouter {
  AppRouter._();

  /// Generate routes based on route name and arguments.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppConstants.routeHome:
        return _buildRoute(const HomeScreen());

      case AppConstants.routeCourtDetail:
        return _buildRoute(const CourtDetailScreen());

      case AppConstants.routeBookingConfirm:
        return _buildRoute(_PlaceholderScreen('Booking Confirmation'));

      case AppConstants.routeBookingSuccess:
        return _buildRoute(_PlaceholderScreen('Booking Success'));

      case AppConstants.routeMyBookings:
        return _buildRoute(_PlaceholderScreen('My Bookings'));

      case AppConstants.routeSplash:
        return _buildRoute(const SplashScreen());

      case AppConstants.routeOnboarding:
        return _buildRoute(_PlaceholderScreen('Onboarding'));

      case AppConstants.routeNotifications:
        return _buildRoute(_PlaceholderScreen('Notifications'));

      case AppConstants.routeProfile:
        return _buildRoute(_PlaceholderScreen('Profile'));

      case AppConstants.routeOwnerPendingApproval:
        return _buildRoute(const PendingApprovalScreen());

      case AppConstants.routeOwnerDashboard:
        return _buildRoute(const OwnerDashboardScreen());

      default:
        return _buildRoute(_PlaceholderScreen('Unknown Route'));
    }
  }

  /// Helper method to build a material page route.
  static MaterialPageRoute<dynamic> _buildRoute(Widget page) {
    return MaterialPageRoute(builder: (context) => page);
  }
}

/// Placeholder screen for routes that are not yet implemented.
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen(this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '$title Screen',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Coming soon...'),
          ],
        ),
      ),
    );
  }
}

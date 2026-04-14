import 'package:flutter/material.dart';

import '../../../features/customer/screens/court_detail_screen.dart';
import '../../../features/customer/screens/home_screen.dart';
import '../../../features/customer/screens/splash_screen.dart';
import 'app_constants.dart';

/// Navigation router for the application.
class AppRouter {
  AppRouter._();

  /// Generate routes based on route name and arguments.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppConstants.routeHome:
        return _buildRoute(const HomeScreen(), settings: settings);

      case AppConstants.routeCourtDetail:
        return _buildRoute(const CourtDetailScreen(), settings: settings);

      case AppConstants.routeBookingConfirm:
        return _buildRoute(
          _PlaceholderScreen('Booking Confirmation'),
          settings: settings,
        );

      case AppConstants.routeBookingSuccess:
        return _buildRoute(
          _PlaceholderScreen('Booking Success'),
          settings: settings,
        );

      case AppConstants.routeMyBookings:
        return _buildRoute(
          _PlaceholderScreen('My Bookings'),
          settings: settings,
        );

      case AppConstants.routeSplash:
        return _buildRoute(const SplashScreen(), settings: settings);

      case AppConstants.routeOnboarding:
        return _buildRoute(
          _PlaceholderScreen('Onboarding'),
          settings: settings,
        );

      case AppConstants.routeNotifications:
        return _buildRoute(
          _PlaceholderScreen('Notifications'),
          settings: settings,
        );

      case AppConstants.routeProfile:
        return _buildRoute(_PlaceholderScreen('Profile'), settings: settings);

      default:
        return _buildRoute(
          _PlaceholderScreen('Unknown Route'),
          settings: settings,
        );
    }
  }

  /// Helper method to build a material page route.
  static MaterialPageRoute<dynamic> _buildRoute(
    Widget page, {
    RouteSettings? settings,
  }) {
    return MaterialPageRoute(settings: settings, builder: (context) => page);
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

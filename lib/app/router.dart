// lib/app/router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:turf_booking/features/auth/providers/auth_providers.dart';
import 'package:turf_booking/features/auth/screens/login_screen.dart';
import 'package:turf_booking/features/auth/screens/register_screen.dart';
import 'package:turf_booking/features/auth/screens/email_confirmation_screen.dart';
import 'package:turf_booking/features/auth/screens/mode_selection_screen.dart';
import 'package:turf_booking/features/customer/screens/court_detail_screen.dart';
import 'package:turf_booking/features/customer/screens/home_screen.dart';
import 'package:turf_booking/features/customer/screens/splash_screen.dart';
import 'package:turf_booking/features/customer/screens/onboarding_screen.dart';
import 'package:turf_booking/features/customer/screens/venue_detail_screen.dart';
import 'package:turf_booking/features/customer/screens/my_bookings_screen.dart';
import 'package:turf_booking/features/customer/screens/profile_screen.dart';
import 'package:turf_booking/features/customer/screens/cart_screen.dart';
import 'package:turf_booking/features/customer/screens/booking_confirmation_screen.dart';
import 'package:turf_booking/features/customer/data/models/booking_args.dart';
import 'package:turf_booking/features/customer/data/models/stadium_model.dart';
import 'package:turf_booking/features/owner/screens/owner_dashboard_screen.dart';
import 'package:turf_booking/features/owner/screens/pending_approval_screen.dart';
import 'package:turf_booking/features/owner/screens/owner_application_screen.dart';
import 'package:turf_booking/features/owner/screens/owner_bookings_screen.dart';
import 'package:turf_booking/features/owner/screens/owner_add_stadium_screen.dart';

import 'package:turf_booking/features/admin/screens/admin_main_screen.dart';

import 'package:turf_booking/features/owner/screens/owner_stadium_manage_screen.dart';
import 'package:turf_booking/features/owner/screens/owner_stadium_edit_screen.dart';
import 'package:turf_booking/features/owner/screens/owner_court_edit_screen.dart';
import 'package:turf_booking/features/owner/screens/owner_gateway_screen.dart';
import 'package:turf_booking/app/constants/app_constants.dart';

part 'router.g.dart';

@riverpod
GoRouter router(Ref ref) {
  // Watch the auth state stream. This triggers a redirect whenever auth changes.
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppConstants.routeSplash,
    redirect: (context, state) {
      // 1. Check if the stream is still loading
      if (authState.isLoading) return null;

      final user = authState.value;
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToRegister = state.matchedLocation == '/register';
      final isGoingToEmailConfirmation =
          state.matchedLocation == '/email-confirmation';
      final isGoingToSplash = state.matchedLocation == AppConstants.routeSplash;
      final isGoingToOnboarding =
          state.matchedLocation == AppConstants.routeOnboarding;

      // Unauthenticated users are allowed on Login, Register, and Email Confirmation
      final isAuthScreen =
          isGoingToLogin ||
          isGoingToRegister ||
          isGoingToEmailConfirmation ||
          isGoingToSplash ||
          isGoingToOnboarding;

      // 2. Unauthenticated users can ONLY go to auth screens
      if (user == null) {
        return isAuthScreen ? null : '/login';
      }

      // 3. If logged in, block them from seeing the login/register screens
      if (isGoingToLogin || isGoingToRegister) {
        return '/mode-selection';
      }

      // 4. Role-based Route Protection for Owners
      final isGoingToOwnerArea = state.matchedLocation.startsWith('/owner');
      if (isGoingToOwnerArea) {
        // If they are not an owner yet, they can ONLY access the application or pending screen
        if (!user.isOwner) {
          if (state.matchedLocation != '/owner/application' &&
              state.matchedLocation != '/owner/pending-approval') {
            return '/owner/application';
          }
        }
        // If they ARE an owner but not approved, lock them to pending
        else if (!user.isApproved &&
            state.matchedLocation != '/owner/pending-approval') {
          return '/owner/pending-approval';
        }
      }

      // 5. Role-based Route Protection for Admins
      final isGoingToAdminArea = state.matchedLocation.startsWith('/admin');
      if (isGoingToAdminArea && !user.isAdmin) {
        return '/mode-selection';
      }

      return null; // All checks passed, let them proceed
    },
    routes: [
      GoRoute(
        path: AppConstants.routeSplash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppConstants.routeOnboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/email-confirmation',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return EmailConfirmationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/mode-selection',
        builder: (context, state) => const ModeSelectionScreen(),
      ),
      GoRoute(
        path: '/customer/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/venue-detail',
        builder: (context, state) {
          final venue = state.extra as Stadium;
          return VenueDetailScreen(venue: venue);
        },
      ),
      GoRoute(
        path: '/court-detail',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          arguments: state.extra,
          child: const CourtDetailScreen(),
        ),
      ),
      GoRoute(
        path: '/booking-confirm',
        builder: (context, state) {
          final args = state.extra as BookingArgs;
          return BookingConfirmationScreen(args: args);
        },
      ),
      GoRoute(
        path: '/customer/my-bookings',
        builder: (context, state) =>
            MyBookingsScreen(toastMessage: state.uri.queryParameters['toast']),
      ),
      GoRoute(
        path: '/customer/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/customer/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/owner/gateway',
        builder: (context, state) => const OwnerGatewayScreen(),
      ),
      GoRoute(
        path: '/owner/dashboard',
        builder: (context, state) => const OwnerDashboardScreen(),
      ),
      GoRoute(
        path: '/owner/application',
        builder: (context, state) => const OwnerApplicationScreen(),
      ),
      GoRoute(
        path: '/owner/pending-approval',
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: '/owner/bookings',
        builder: (context, state) => const OwnerBookingsScreen(),
      ),
      GoRoute(
        path: '/owner/add-stadium',
        builder: (context, state) => const OwnerAddStadiumScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminMainScreen(),
      ),
      GoRoute(
        path: '/owner/manage',
        builder: (context, state) => const OwnerStadiumManageScreen(),
      ),
      GoRoute(
        path: '/owner/edit-stadium',
        builder: (context, state) => const OwnerStadiumEditScreen(),
      ),
      GoRoute(
        path: '/owner/edit-court/:courtId',
        builder: (context, state) =>
            OwnerCourtEditScreen(courtId: state.pathParameters['courtId']!),
      ),
    ],
  );
}

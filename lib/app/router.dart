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
import 'package:turf_booking/features/customer/data/models/court_detail_args.dart';
import 'package:turf_booking/features/customer/data/models/court_model.dart';
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
      final isGoingToSplash = state.matchedLocation == AppConstants.routeSplash;

      // 1. Check if the stream is still loading
      if (authState.isLoading) {
        return isGoingToSplash ? null : AppConstants.routeSplash;
      }

      final user = authState.value;
      final isGoingToLogin = state.matchedLocation == AppConstants.routeLogin;
      final isGoingToRegister =
          state.matchedLocation == AppConstants.routeRegister;
      final isGoingToEmailConfirmation =
          state.matchedLocation == AppConstants.routeEmailConfirmation;
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
        return isAuthScreen ? null : AppConstants.routeLogin;
      }

      // 3. If logged in, block them from seeing the login/register screens
      if (isGoingToLogin || isGoingToRegister) {
        return AppConstants.routeModeSelection;
      }

      // 4. Role-based Route Protection for Owners
      final isGoingToOwnerArea = state.matchedLocation.startsWith(
        AppConstants.routeOwnerPrefix,
      );
      if (isGoingToOwnerArea) {
        // If they are not an owner yet, they can ONLY access the application or pending screen
        if (!user.isOwner) {
          if (state.matchedLocation != AppConstants.routeOwnerApplication &&
              state.matchedLocation != AppConstants.routeOwnerPendingApproval) {
            return AppConstants.routeOwnerApplication;
          }
        }
        // If they ARE an owner but not approved, lock them to pending
        else if (!user.isApproved &&
            state.matchedLocation != AppConstants.routeOwnerPendingApproval) {
          return AppConstants.routeOwnerPendingApproval;
        }
      }

      // 5. Role-based Route Protection for Admins
      final isGoingToAdminArea = state.matchedLocation.startsWith(
        AppConstants.routeAdmin,
      );
      if (isGoingToAdminArea && !user.isAdmin) {
        return AppConstants.routeModeSelection;
      }

      return null; // All checks passed, let them proceed
    },
    routes: [
      GoRoute(
        name: 'splash',
        path: AppConstants.routeSplash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        name: 'onboarding',
        path: AppConstants.routeOnboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        name: 'login',
        path: AppConstants.routeLogin,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        name: 'register',
        path: AppConstants.routeRegister,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        name: 'emailConfirmation',
        path: AppConstants.routeEmailConfirmation,
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return EmailConfirmationScreen(email: email);
        },
      ),
      GoRoute(
        name: 'modeSelection',
        path: AppConstants.routeModeSelection,
        builder: (context, state) => const ModeSelectionScreen(),
      ),
      GoRoute(
        name: 'customerHome',
        path: AppConstants.routeCustomerHome,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        name: 'venueDetail',
        path: AppConstants.routeVenueDetail,
        builder: (context, state) {
          final venue = state.extra;
          if (venue is! Stadium) {
            return _invalidRouteDataScreen('Venue details are unavailable.');
          }
          return VenueDetailScreen(venue: venue);
        },
      ),
      GoRoute(
        name: 'courtDetail',
        path: AppConstants.routeCourtDetail,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! Court && extra is! CourtDetailArgs) {
            return _invalidRouteDataScreen('Court details are unavailable.');
          }
          return CourtDetailScreen(initialArgs: extra);
        },
      ),
      GoRoute(
        name: 'bookingConfirm',
        path: AppConstants.routeBookingConfirm,
        builder: (context, state) {
          final args = state.extra;
          if (args is! BookingArgs) {
            return _invalidRouteDataScreen('Booking details are unavailable.');
          }
          return BookingConfirmationScreen(args: args);
        },
      ),
      GoRoute(
        name: 'customerMyBookings',
        path: AppConstants.routeMyBookings,
        builder: (context, state) =>
            MyBookingsScreen(toastMessage: state.uri.queryParameters['toast']),
      ),
      GoRoute(
        name: 'customerCart',
        path: AppConstants.routeCart,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        name: 'customerProfile',
        path: AppConstants.routeCustomerProfile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        name: 'ownerGateway',
        path: AppConstants.routeOwnerGateway,
        builder: (context, state) => const OwnerGatewayScreen(),
      ),
      GoRoute(
        name: 'ownerDashboard',
        path: AppConstants.routeOwnerDashboard,
        builder: (context, state) => const OwnerDashboardScreen(),
      ),
      GoRoute(
        name: 'ownerApplication',
        path: AppConstants.routeOwnerApplication,
        builder: (context, state) => const OwnerApplicationScreen(),
      ),
      GoRoute(
        name: 'ownerPendingApproval',
        path: AppConstants.routeOwnerPendingApproval,
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        name: 'ownerBookings',
        path: AppConstants.routeOwnerBookings,
        builder: (context, state) => const OwnerBookingsScreen(),
      ),
      GoRoute(
        name: 'ownerAddStadium',
        path: AppConstants.routeOwnerAddStadium,
        builder: (context, state) => const OwnerAddStadiumScreen(),
      ),
      GoRoute(
        name: 'adminMain',
        path: AppConstants.routeAdmin,
        builder: (context, state) => const AdminMainScreen(),
      ),
      GoRoute(
        name: 'ownerManage',
        path: AppConstants.routeOwnerManage,
        builder: (context, state) => const OwnerStadiumManageScreen(),
      ),
      GoRoute(
        name: 'ownerEditStadium',
        path: AppConstants.routeOwnerEditStadium,
        builder: (context, state) => const OwnerStadiumEditScreen(),
      ),
      GoRoute(
        name: 'ownerEditCourt',
        path: AppConstants.routeOwnerEditCourt,
        builder: (context, state) =>
            OwnerCourtEditScreen(courtId: state.pathParameters['courtId']!),
      ),
    ],
  );
}

Widget _invalidRouteDataScreen(String message) {
  return Scaffold(body: Center(child: Text(message)));
}

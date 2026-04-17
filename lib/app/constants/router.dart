// lib/app/router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:turf_booking/features/auth/providers/auth_providers.dart';
import 'package:turf_booking/features/auth/screens/login_screen.dart';
import 'package:turf_booking/features/auth/screens/register_screen.dart';
import 'package:turf_booking/features/auth/screens/email_confirmation_screen.dart';
import 'package:turf_booking/features/auth/screens/mode_selection_screen.dart';
import 'package:turf_booking/features/customer/screens/home_screen.dart';
import 'package:turf_booking/features/owner/screens/owner_dashboard_screen.dart';
import 'package:turf_booking/features/owner/screens/pending_approval_screen.dart';

part 'router.g.dart';

@riverpod
GoRouter router(Ref ref) {
  // Watch the auth state stream. This triggers a redirect whenever auth changes.
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/mode-selection',
    redirect: (context, state) {
      // 1. Check if the stream is still loading
      if (authState.isLoading) return null;

      final user = authState.value;
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToRegister = state.matchedLocation == '/register';
      final isGoingToEmailConfirmation = state.matchedLocation == '/email-confirmation';
      
      // Unauthenticated users are allowed on Login, Register, and Email Confirmation
      final isAuthScreen = isGoingToLogin || isGoingToRegister || isGoingToEmailConfirmation;

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
        // If they aren't approved, force them to the pending screen
        if (!user.isApproved && state.matchedLocation != '/owner/pending-approval') {
          return '/owner/pending-approval';
        }
      }

      return null; // All checks passed, let them proceed
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
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
        path: '/owner/dashboard',
        builder: (context, state) => const OwnerDashboardScreen(),
      ),
      GoRoute(
        path: '/owner/pending-approval',
        builder: (context, state) => const PendingApprovalScreen(),
      ),
    ],
  );
}
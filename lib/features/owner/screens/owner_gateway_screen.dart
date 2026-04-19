import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:turf_booking/app/theme/app_colors.dart';
import 'package:turf_booking/features/owner/providers/stadium_providers.dart';

/// A dedicated routing gateway for approved owners.
///
/// This screen resolves the async "does this owner have a stadium?"
/// question that cannot be answered inside the synchronous GoRouter
/// redirect. It watches [currentStadiumProvider] and navigates to:
///   - `/owner/add-stadium` if the owner has no stadium yet.
///   - `/owner/dashboard` if a stadium exists.
class OwnerGatewayScreen extends ConsumerWidget {
  const OwnerGatewayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stadiumAsync = ref.watch(currentStadiumProvider);

    return stadiumAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(currentStadiumProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (stadium) {
        // Schedule the navigation for after the current frame to avoid
        // calling context.go() during the build phase.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          if (stadium == null) {
            context.go('/owner/add-stadium');
          } else {
            context.go('/owner/dashboard');
          }
        });

        // Return an empty scaffold while the post-frame callback fires.
        return const Scaffold(backgroundColor: AppColors.background);
      },
    );
  }
}

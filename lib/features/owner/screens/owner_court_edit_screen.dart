import 'package:flutter/material.dart';
import 'package:turf_booking/app/theme/app_colors.dart';

/// Placeholder — will be refactored to ConsumerStatefulWidget with live Supabase data.
/// Now receives courtId from the URL path parameter instead of state.extra.
class OwnerCourtEditScreen extends StatelessWidget {
  final String courtId;
  const OwnerCourtEditScreen({super.key, required this.courtId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'Edit Court: $courtId\n(Refactor pending)',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

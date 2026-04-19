import 'package:flutter/material.dart';
import 'package:turf_booking/app/theme/app_colors.dart';

/// Placeholder — will be refactored to ConsumerWidget with live Supabase data.
class OwnerStadiumManageScreen extends StatelessWidget {
  const OwnerStadiumManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'Manage Stadium\n(Refactor pending)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

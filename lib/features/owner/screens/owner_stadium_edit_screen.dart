import 'package:flutter/material.dart';
import 'package:turf_booking/app/theme/app_colors.dart';

/// Placeholder — will be refactored to ConsumerStatefulWidget with live Supabase data.
class OwnerStadiumEditScreen extends StatelessWidget {
  const OwnerStadiumEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'Edit Stadium\n(Refactor pending)',
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

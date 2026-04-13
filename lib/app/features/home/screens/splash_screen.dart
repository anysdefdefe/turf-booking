import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goToHome();
  }

  Future<void> _goToHome() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(AppConstants.routeHome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.sports_tennis_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Courtly',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Book your turf in seconds',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 22),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

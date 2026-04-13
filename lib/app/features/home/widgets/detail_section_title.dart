import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// A reusable widget for displaying section titles in the detail page.
class DetailSectionTitle extends StatelessWidget {
  final String title;

  const DetailSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

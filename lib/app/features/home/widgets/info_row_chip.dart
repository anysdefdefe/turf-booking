import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// A reusable widget for displaying info with an icon, label, and color.
class InfoRowChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const InfoRowChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

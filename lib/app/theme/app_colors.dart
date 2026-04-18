import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core Theme
  static const Color primary = Color(0xFF00C27C);     // Turf Green
  static const Color primaryDark = Color(0xFF00995F);
  
  // Surfaces
  static const Color background = Color(0xFFF6F6F7);  // Sleek off-white for main backgrounds
  static const Color surface = Color(0xFFFFFFFF);     // Pure white for cards/surfaces
  
  // Typography (Sharp Monochrome)
  static const Color textPrimary = Color(0xFF0E0E10); // Heavy almost-black
  static const Color textSecondary = Color(0xFF71717A); // Zinc grey for subtitles
  static const Color textMuted = Color(0xFFA1A1AA);   // Lighter zinc for placeholders
  
  // Accents & Structure
  static const Color divider = Color(0xFFE4E4E7);     // Subtle borders
  static const Color error = Color(0xFFDC2626);       // Red for failed states
  
  // Deprecated/Legacy bindings for backward compatibility in other files
  static const Color secondary = Color(0xFF1A1A2E);
  static const Color accent = Color(0xFFFFD166);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color chipSelected = Color(0xFF00C27C);
  static const Color chipUnselected = Color(0xFFEEEEF6);
  static const Color star = Color(0xFFFFD166);
  static const Color badgeBg = Color(0xFFE8FFF5);
  static const Color badgeText = Color(0xFF00995F);
}

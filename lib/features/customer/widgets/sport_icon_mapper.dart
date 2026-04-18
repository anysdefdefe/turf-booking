import 'package:flutter/material.dart';

IconData sportIconForName(String sport) {
  final key = sport.toLowerCase().trim();

  if (key.contains('football') || key.contains('futsal')) {
    return Icons.sports_soccer_rounded;
  }
  if (key.contains('cricket')) {
    return Icons.sports_cricket_rounded;
  }
  if (key.contains('badminton')) {
    return Icons.sports_tennis_rounded;
  }
  if (key.contains('tennis') ||
      key.contains('padel') ||
      key.contains('squash')) {
    return Icons.sports_tennis_rounded;
  }
  if (key.contains('basketball')) {
    return Icons.sports_basketball_rounded;
  }
  if (key.contains('volley')) {
    return Icons.sports_volleyball_rounded;
  }
  if (key.contains('hockey')) {
    return Icons.sports_hockey_rounded;
  }
  if (key.contains('swimming') || key.contains('pool')) {
    return Icons.pool_rounded;
  }
  if (key.contains('boxing')) {
    return Icons.sports_mma_rounded;
  }
  if (key.contains('billiard') || key.contains('snooker')) {
    return Icons.sports_bar_rounded;
  }
  if (key.contains('table tennis')) {
    return Icons.sports_tennis_rounded;
  }
  if (key.contains('esport') || key.contains('gaming')) {
    return Icons.sports_esports_rounded;
  }
  if (key.contains('rifle') || key.contains('shoot')) {
    return Icons.gps_fixed_rounded;
  }
  if (key.contains('gym')) {
    return Icons.fitness_center_rounded;
  }

  return Icons.sports_rounded;
}

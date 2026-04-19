import 'package:shared_preferences/shared_preferences.dart';

class OnboardingRepository {
  OnboardingRepository._();

  static const String _kOnboardingCompleted = 'onboarding_completed_v1';

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingCompleted) ?? false;
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingCompleted, true);
  }
}

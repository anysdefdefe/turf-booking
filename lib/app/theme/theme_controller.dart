import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global theme mode with persistence. Default is [ThemeMode.system].
///
/// Listeners refresh when the mode changes or when device brightness changes while in system mode.
class ThemeController extends ValueNotifier<ThemeMode> {
  static const String _themeModeKey = 'theme_mode_v1';
  static final ThemeController instance = ThemeController._internal();

  bool _hasLoaded = false;
  VoidCallback? _prevBrightnessHandler;

  ThemeController._internal() : super(ThemeMode.system) {
    final dispatcher = SchedulerBinding.instance.platformDispatcher;
    _prevBrightnessHandler = dispatcher.onPlatformBrightnessChanged;
    dispatcher.onPlatformBrightnessChanged = () {
      _prevBrightnessHandler?.call();
      if (value == ThemeMode.system) {
        notifyListeners();
      }
    };
    _loadThemeMode();
  }

  ThemeMode get themeMode => value;

  /// Effective dark flag for icons and copy (respects system when applicable).
  bool get isDarkMode {
    switch (value) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return SchedulerBinding
                .instance
                .platformDispatcher
                .platformBrightness ==
            Brightness.dark;
    }
  }

  bool get hasLoaded => _hasLoaded;

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final storedMode = prefs.getString(_themeModeKey);

    value = _themeModeFromStorage(storedMode) ?? ThemeMode.system;
    _hasLoaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    value = mode;
    _hasLoaded = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _themeModeToStorage(mode));
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    await setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> useSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }

  ThemeMode? _themeModeFromStorage(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return null;
    }
  }

  String _themeModeToStorage(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

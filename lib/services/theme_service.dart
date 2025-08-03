import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../constants/app_constants.dart';

class ThemeService extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;
  Color _accent = AppColors.accent;

  ThemeMode get mode => _mode;
  Color get accentColor => _accent;

  ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _accent,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.lightBackground,
        cardColor: AppColors.lightCard,
        textTheme: ThemeData.light()
            .textTheme
            .copyWith(
              bodySmall: const TextStyle(fontSize: AppConstants.fontSize14),
              bodyMedium: const TextStyle(fontSize: AppConstants.fontSize16),
              bodyLarge: const TextStyle(fontSize: AppConstants.fontSize18),
              labelSmall: const TextStyle(fontSize: AppConstants.fontSize12),
            )
            .apply(
              fontFamily: 'Roboto',
              bodyColor: AppColors.textPrimaryLight,
              displayColor: AppColors.textPrimaryLight,
            ),
      );

  ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _accent,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        cardColor: AppColors.darkCard,
        textTheme: ThemeData.dark()
            .textTheme
            .copyWith(
              bodySmall: const TextStyle(fontSize: AppConstants.fontSize14),
              bodyMedium: const TextStyle(fontSize: AppConstants.fontSize16),
              bodyLarge: const TextStyle(fontSize: AppConstants.fontSize18),
              labelSmall: const TextStyle(fontSize: AppConstants.fontSize12),
            )
            .apply(
              fontFamily: 'Roboto',
              bodyColor: AppColors.textPrimaryDark,
              displayColor: AppColors.textPrimaryDark,
            ),
      );

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(AppConstants.prefsThemeMode);
    if (name == ThemeMode.light.name) {
      _mode = ThemeMode.light;
    } else {
      _mode = ThemeMode.dark;
    }
    _accent =
        Color(prefs.getInt(AppConstants.prefsAccentColor) ?? AppColors.accent.value);
    AppColors.accent = _accent;
    notifyListeners();
  }

  Future<void> toggle() async {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefsThemeMode, _mode.name);
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    if (_accent == color) return;
    _accent = color;
    AppColors.accent = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefsAccentColor, color.value);
    notifyListeners();
  }
}

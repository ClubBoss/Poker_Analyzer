import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

class ThemeService extends ChangeNotifier {
  static const _key = 'theme_mode';
  static const _accentKey = 'accent_color';
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
        scaffoldBackgroundColor: AppColors.background,
        cardColor: AppColors.cardBackground,
        textTheme: ThemeData.light().textTheme.apply(
              fontFamily: 'Roboto',
              bodyColor: Colors.black,
              displayColor: Colors.black,
            ),
      );

  ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _accent,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.background,
        cardColor: AppColors.cardBackground,
        textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'Roboto',
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
      );

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_key);
    if (name == ThemeMode.light.name) {
      _mode = ThemeMode.light;
    } else {
      _mode = ThemeMode.dark;
    }
    _accent = Color(prefs.getInt(_accentKey) ?? AppColors.accent.value);
    AppColors.accent = _accent;
    notifyListeners();
  }

  Future<void> toggle() async {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _mode.name);
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    if (_accent == color) return;
    _accent = color;
    AppColors.accent = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentKey, color.value);
    notifyListeners();
  }
}

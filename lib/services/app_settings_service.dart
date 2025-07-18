import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  static final AppSettingsService instance = AppSettingsService._();
  AppSettingsService._();

  static const _notificationsKey = 'notifications_enabled';
  static const _newTrainerUiKey = 'use_new_trainer_ui';

  bool _notificationsEnabled = true;
  bool _useNewTrainerUi = false;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get useNewTrainerUi => _useNewTrainerUi;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
    _useNewTrainerUi = prefs.getBool(_newTrainerUiKey) ?? false;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
  }

  Future<void> setUseNewTrainerUi(bool value) async {
    _useNewTrainerUi = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_newTrainerUiKey, value);
  }
}

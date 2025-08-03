
class AppSettingsService {
  static final AppSettingsService instance = AppSettingsService._();
  AppSettingsService._();

  static const _notificationsKey = 'notifications_enabled';
  static const _newTrainerUiKey = 'use_new_trainer_ui';
  static const _useIcmKey = 'use_icm_mode';

  bool _notificationsEnabled = true;
  bool _useNewTrainerUi = false;
  bool _useIcm = false;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get useNewTrainerUi => _useNewTrainerUi;
  bool get useIcm => _useIcm;

  Future<void> load() async {
    final prefs = await PreferencesService.getInstance();
    _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
    _useNewTrainerUi = prefs.getBool(_newTrainerUiKey) ?? false;
    _useIcm = prefs.getBool(_useIcmKey) ?? false;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    final prefs = await PreferencesService.getInstance();
    await prefs.setBool(_notificationsKey, value);
  }

  Future<void> setUseNewTrainerUi(bool value) async {
    _useNewTrainerUi = value;
    final prefs = await PreferencesService.getInstance();
    await prefs.setBool(_newTrainerUiKey, value);
  }

  Future<void> setUseIcm(bool value) async {
    _useIcm = value;
    final prefs = await PreferencesService.getInstance();
    await prefs.setBool(_useIcmKey, value);
  }
}

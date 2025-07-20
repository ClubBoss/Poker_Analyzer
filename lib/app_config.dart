class AppConfig {
  AppConfig._();
  static final instance = AppConfig._();
  bool archiveAutoClean = false;
  bool showSmartPathHints = true;
  bool devUnlockOverride = false;
}

final appConfig = AppConfig.instance;

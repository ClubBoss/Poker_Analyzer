class AppConfig {
  AppConfig._();
  static final instance = AppConfig._();
  bool archiveAutoClean = false;
  bool showSmartPathHints = true;
}

final appConfig = AppConfig.instance;

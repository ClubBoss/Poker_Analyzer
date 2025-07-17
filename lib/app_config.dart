class AppConfig {
  AppConfig._();
  static final instance = AppConfig._();
  bool archiveAutoClean = false;
}

final appConfig = AppConfig.instance;

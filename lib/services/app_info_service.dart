import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Provides metadata about the application such as version and build mode.
class AppInfoService {
  /// Returns the application version obtained from the underlying platform.
  Future<String> getAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// Whether the app is running in debug mode.
  bool isDebugMode() => !kReleaseMode;

  /// Whether the app is running in release mode.
  bool isReleaseMode() => kReleaseMode;
}


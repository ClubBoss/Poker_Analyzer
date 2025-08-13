import 'package:flutter/foundation.dart';

/// A simple logging utility that centralizes log output.
///
/// In debug mode, logs are printed to the console. In release mode, this
/// prepares for integration with services like Crashlytics.
class AppLogger {
  AppLogger._();

  static void log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    } else {
      // TODO: Add release logging implementation, e.g., send to Crashlytics.
    }
  }

  static void warn(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ $message');
    } else {
      // TODO: Add release logging implementation, e.g., send to Crashlytics.
    }
  }

  static void error(String message, [Object? error, StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('❌ $message');
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stack != null) {
        debugPrint(stack.toString());
      }
    } else {
      // TODO: Add release logging implementation, e.g., send to Crashlytics.
    }
  }
}

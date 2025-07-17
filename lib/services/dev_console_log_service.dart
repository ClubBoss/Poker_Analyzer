import 'package:flutter/foundation.dart';

class DevConsoleLogService {
  DevConsoleLogService._();
  static final instance = DevConsoleLogService._();
  bool enabled = false;

  void log(String message) {
    if (!enabled) return;
    debugPrint(message);
  }
}

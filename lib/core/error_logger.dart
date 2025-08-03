import 'package:flutter/foundation.dart';

class ErrorLogger {
  ErrorLogger._();
  static final ErrorLogger instance = ErrorLogger._();
  static const int _maxErrors = 100;
  factory ErrorLogger() => instance;

  final List<String> recentErrors = [];

  void logError(String msg, [Object? error, StackTrace? stack]) {
    final timestamp = DateTime.now().toIso8601String();
    var entry = '$timestamp $msg';
    if (error != null) entry += ': $error';
    if (stack != null) entry += '\n$stack';
    recentErrors.add(entry);
    if (recentErrors.length > _maxErrors) {
      recentErrors.removeRange(0, recentErrors.length - _maxErrors);
    }
    debugPrint(entry);
  }
}

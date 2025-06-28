import 'package:flutter/material.dart';

class ErrorLoggerService {
  ErrorLoggerService._();
  static final ErrorLoggerService instance = ErrorLoggerService._();
  factory ErrorLoggerService() => instance;

  final List<String> recentErrors = [];

  void logError(String msg, [Object? error, StackTrace? stack]) {
    final timestamp = DateTime.now().toIso8601String();
    var entry = '$timestamp $msg';
    if (error != null) entry += ': $error';
    if (stack != null) entry += '\n$stack';
    recentErrors.add(entry);
    if (recentErrors.length > 100) {
      recentErrors.removeRange(0, recentErrors.length - 100);
    }
    debugPrint(entry);
  }

  void reportToUser(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
    logError(msg);
  }
}

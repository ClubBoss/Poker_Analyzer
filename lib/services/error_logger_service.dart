import 'package:flutter/material.dart';
import '../core/error_logger.dart';

export '../core/error_logger.dart';

typedef ErrorLoggerService = ErrorLogger;

extension ErrorLoggerReport on ErrorLogger {
  void reportToUser(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
    logError(msg);
  }
}

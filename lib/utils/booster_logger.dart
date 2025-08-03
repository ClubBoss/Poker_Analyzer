import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/user_action_logger.dart';

/// Utility for booster-related debugging and analytics logs.
class BoosterLogger {
  BoosterLogger._();

  /// Prints [message] with a booster prefix and logs it as an event.
  static Future<void> log(String message) async {
    debugPrint('[Booster] $message');
    await UserActionLogger.instance.logEvent({
      'event': 'booster.log',
      'message': message,
    });
  }
}

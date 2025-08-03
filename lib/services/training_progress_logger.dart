import 'dart:async';

import 'user_action_logger.dart';

/// Logs training session start events.
class TrainingProgressLogger {
  TrainingProgressLogger._();

  /// Records the start of a training session for the given [packId].
  static Future<void> startSession(String packId) async {
    unawaited(UserActionLogger.instance.log('training_session_start:$packId'));
  }
}


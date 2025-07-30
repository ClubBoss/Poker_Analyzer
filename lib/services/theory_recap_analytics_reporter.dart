import 'user_action_logger.dart';

/// Reports theory recap trigger analytics.
class TheoryRecapAnalyticsReporter {
  TheoryRecapAnalyticsReporter._();
  static final TheoryRecapAnalyticsReporter instance =
      TheoryRecapAnalyticsReporter._();

  /// Logs a recap event for analytics.
  Future<void> logEvent({
    required String lessonId,
    required String trigger,
    required String outcome,
    required Duration? delay,
  }) async {
    final data = <String, dynamic>{
      'event': 'theory_recap',
      'lessonId': lessonId,
      'trigger': trigger,
      'outcome': outcome,
      if (delay != null) 'delayMs': delay.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await UserActionLogger.instance.logEvent(data);
  }
}

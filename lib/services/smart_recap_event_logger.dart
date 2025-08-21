import 'recap_history_tracker.dart';
import 'recap_auto_repeat_scheduler.dart';

/// Lightweight logger for recap banner impressions and actions.
class SmartRecapEventLogger {
  final RecapHistoryTracker history;
  final DateTime Function() _now;
  final RecapAutoRepeatScheduler scheduler;

  SmartRecapEventLogger({
    RecapHistoryTracker? history,
    DateTime Function()? timestampProvider,
    RecapAutoRepeatScheduler? scheduler,
  })  : history = history ?? RecapHistoryTracker.instance,
        _now = timestampProvider ?? DateTime.now,
        scheduler = scheduler ?? RecapAutoRepeatScheduler.instance;

  Future<void> logShown(String lessonId, {String trigger = 'smart'}) {
    return history.logRecapEvent(lessonId, trigger, 'shown', timestamp: _now());
  }

  Future<void> logDismissed(String lessonId, {String trigger = 'smart'}) async {
    await history.logRecapEvent(
      lessonId,
      trigger,
      'dismissed',
      timestamp: _now(),
    );
    await scheduler.scheduleRepeat(lessonId, const Duration(days: 2));
  }

  Future<void> logCompleted(
    String lessonId, {
    String trigger = 'smart',
    bool lowConfidence = false,
    bool highConfidence = false,
  }) async {
    await history.logRecapEvent(
      lessonId,
      trigger,
      'completed',
      timestamp: _now(),
    );
    if (lowConfidence) {
      await scheduler.scheduleRepeat(lessonId, const Duration(days: 1));
    } else if (!highConfidence) {
      // default moderate confidence -> 3 days
      await scheduler.scheduleRepeat(lessonId, const Duration(days: 3));
    }
  }

  Future<void> logTapped(String lessonId, {String trigger = 'smart'}) {
    return history.logRecapEvent(
      lessonId,
      trigger,
      'tapped',
      timestamp: _now(),
    );
  }
}

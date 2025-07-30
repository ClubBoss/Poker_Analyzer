import 'recap_history_tracker.dart';

/// Lightweight logger for recap banner impressions and actions.
class SmartRecapEventLogger {
  final RecapHistoryTracker history;
  final DateTime Function() _now;

  SmartRecapEventLogger({
    RecapHistoryTracker? history,
    DateTime Function()? timestampProvider,
  })  : history = history ?? RecapHistoryTracker.instance,
        _now = timestampProvider ?? DateTime.now;

  Future<void> logShown(String lessonId, {String trigger = 'smart'}) {
    return history.logRecapEvent(
      lessonId,
      trigger,
      'shown',
      timestamp: _now(),
    );
  }

  Future<void> logDismissed(String lessonId, {String trigger = 'smart'}) {
    return history.logRecapEvent(
      lessonId,
      trigger,
      'dismissed',
      timestamp: _now(),
    );
  }

  Future<void> logCompleted(String lessonId, {String trigger = 'smart'}) {
    return history.logRecapEvent(
      lessonId,
      trigger,
      'completed',
      timestamp: _now(),
    );
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

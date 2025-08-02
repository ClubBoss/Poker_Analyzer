import 'user_action_logger.dart';

/// Provides a simple interface for logging analytics events.
class AnalyticsService {
  AnalyticsService._();

  static final instance = AnalyticsService._();

  Future<void> logEvent(String event, Map<String, dynamic> params) async {
    await UserActionLogger.instance.logEvent({
      'event': event,
      ...params,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}

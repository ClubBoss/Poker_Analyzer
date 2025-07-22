import 'user_action_logger.dart';

class EngagementAnalyticsService {
  EngagementAnalyticsService._();

  static final instance = EngagementAnalyticsService._();

  Future<void> logEvent(
    String event, {
    required String source,
    String? tag,
    String? packId,
  }) async {
    final data = <String, dynamic>{
      'event': event,
      'source': source,
      if (tag != null) 'tag': tag,
      if (packId != null) 'packId': packId,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await UserActionLogger.instance.logEvent(data);
  }
}

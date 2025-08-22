abstract class AnalyticsAdapter {
  Future<void> send(String event, Map<String, Object?> data);
}

class NullAnalyticsAdapter implements AnalyticsAdapter {
  NullAnalyticsAdapter();
  @override
  Future<void> send(String event, Map<String, Object?> data) async {}
}

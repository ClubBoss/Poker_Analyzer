import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/smart_recap_event_logger.dart';
import 'package:poker_analyzer/services/recap_history_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RecapHistoryTracker.instance.resetForTest();
  });

  test('logs shown event with default trigger', () async {
    final logger = SmartRecapEventLogger();
    await logger.logShown('l1');
    final events = await RecapHistoryTracker.instance.getHistory();
    expect(events.length, 1);
    expect(events.first.lessonId, 'l1');
    expect(events.first.eventType, 'shown');
    expect(events.first.trigger, 'smart');
  });

  test('allows injecting timestamp', () async {
    final t = DateTime(2020, 1, 1);
    final logger = SmartRecapEventLogger(timestampProvider: () => t);
    await logger.logDismissed('l2', trigger: 'banner');
    final events = await RecapHistoryTracker.instance.getHistory();
    expect(events.first.timestamp, t);
    expect(events.first.trigger, 'banner');
    expect(events.first.eventType, 'dismissed');
  });
}

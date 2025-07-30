import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/theory_recap_analytics_reporter.dart';
import 'package:poker_analyzer/services/user_action_logger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserActionLogger.instance.load();
  });

  test('logs recap analytics event', () async {
    await TheoryRecapAnalyticsReporter.instance.logEvent(
      lessonId: 'l1',
      trigger: 't',
      outcome: 'shown',
      delay: const Duration(seconds: 5),
    );
    expect(UserActionLogger.instance.events.last['event'], 'theory_recap');
    expect(UserActionLogger.instance.events.last['lessonId'], 'l1');
    expect(UserActionLogger.instance.events.last['trigger'], 't');
    expect(UserActionLogger.instance.events.last['outcome'], 'shown');
    expect(UserActionLogger.instance.events.last['delayMs'], 5000);
  });
}

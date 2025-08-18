import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/recap_completion_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RecapCompletionTracker.instance.resetForTest();
  });

  test('logs and retrieves recent completions', () async {
    await RecapCompletionTracker.instance.logCompletion(
      'l1',
      'recap',
      const Duration(seconds: 5),
    );
    final list = await RecapCompletionTracker.instance.getRecentCompletions();
    expect(list.length, 1);
    expect(list.first.lessonId, 'l1');
    expect(list.first.tag, 'recap');
    expect(list.first.duration.inSeconds, 5);
  });

  test('older completions filtered by window', () async {
    final now = DateTime.now();
    await RecapCompletionTracker.instance.logCompletion(
      'l1',
      'recap',
      const Duration(seconds: 1),
      timestamp: now.subtract(const Duration(days: 8)),
    );
    final list = await RecapCompletionTracker.instance.getRecentCompletions();
    expect(list, isEmpty);
  });
}

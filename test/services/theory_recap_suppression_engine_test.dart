import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/theory_recap_suppression_engine.dart';
import 'package:poker_analyzer/models/recap_analytics_summary.dart';
import 'package:poker_analyzer/services/theory_recap_analytics_summarizer.dart';

class _StubSummarizer extends TheoryRecapAnalyticsSummarizer {
  final RecapAnalyticsSummary _summary;
  _StubSummarizer(this._summary)
    : super(loader: ({int limit = 50}) async => []);
  @override
  Future<RecapAnalyticsSummary> summarize({int limit = 50}) async => _summary;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('suppresses low acceptance trigger', () async {
    final summarizer = _StubSummarizer(
      const RecapAnalyticsSummary(
        acceptanceRatesByTrigger: {'weakness': 10},
        mostDismissedLessonIds: [],
        ignoredStreakCount: 0,
      ),
    );
    final engine = TheoryRecapSuppressionEngine(summarizer: summarizer);
    final result = await engine.shouldSuppress(
      lessonId: 'l1',
      trigger: 'weakness',
    );
    expect(result, isTrue);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('theory_recap_suppressions');
    expect(raw, isNotNull);
    expect(raw!.contains('trigger:weakness'), isTrue);
  });

  test('suppresses globally on ignored streak', () async {
    final summarizer = _StubSummarizer(
      const RecapAnalyticsSummary(
        acceptanceRatesByTrigger: {},
        mostDismissedLessonIds: [],
        ignoredStreakCount: 3,
      ),
    );
    final engine = TheoryRecapSuppressionEngine(summarizer: summarizer);
    final result = await engine.shouldSuppress(lessonId: 'l1', trigger: 'any');
    expect(result, isTrue);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('theory_recap_suppressions');
    expect(raw, isNotNull);
    expect(raw!.contains('global'), isTrue);
  });

  test('returns false when no rules matched', () async {
    final summarizer = _StubSummarizer(
      const RecapAnalyticsSummary(
        acceptanceRatesByTrigger: {'weakness': 80},
        mostDismissedLessonIds: [],
        ignoredStreakCount: 0,
      ),
    );
    final engine = TheoryRecapSuppressionEngine(summarizer: summarizer);
    final result = await engine.shouldSuppress(
      lessonId: 'l1',
      trigger: 'weakness',
    );
    expect(result, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theory_recap_suppressions'), isNull);
  });
}

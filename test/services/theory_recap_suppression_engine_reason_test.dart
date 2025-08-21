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

  test('returns lowAcceptance reason', () async {
    final summarizer = _StubSummarizer(
      const RecapAnalyticsSummary(
        acceptanceRatesByTrigger: {'weakness': 10},
        mostDismissedLessonIds: [],
        ignoredStreakCount: 0,
      ),
    );
    final engine = TheoryRecapSuppressionEngine(summarizer: summarizer);
    final reason = await engine.getSuppressionReason(
      lessonId: 'l1',
      trigger: 'weakness',
    );
    expect(reason, 'lowAcceptance');
  });

  test('returns triggerCooldown when marked', () async {
    final summarizer = _StubSummarizer(
      const RecapAnalyticsSummary(
        acceptanceRatesByTrigger: {'weakness': 10},
        mostDismissedLessonIds: [],
        ignoredStreakCount: 0,
      ),
    );
    final engine = TheoryRecapSuppressionEngine(summarizer: summarizer);
    await engine.shouldSuppress(lessonId: 'l1', trigger: 'weakness');
    final reason = await engine.getSuppressionReason(
      lessonId: 'l1',
      trigger: 'weakness',
    );
    expect(reason, 'triggerCooldown');
  });
}

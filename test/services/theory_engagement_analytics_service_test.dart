import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/recall_boost_interaction_logger.dart';
import 'package:poker_analyzer/services/theory_engagement_analytics_service.dart';
import 'package:poker_analyzer/services/theory_mini_lesson_usage_tracker.dart';
import 'package:poker_analyzer/services/theory_recall_efficiency_evaluator_service.dart';

class _FakeEfficiencyService extends TheoryRecallEfficiencyEvaluatorService {
  final Map<String, double> scores;
  _FakeEfficiencyService(this.scores) : super();

  @override
  Future<Map<String, double>> getEfficiencyScoresByTag() async => scores;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('aggregates engagement stats per lesson', () async {
    final usageTracker = TheoryMiniLessonUsageTracker.instance;
    await usageTracker.logManualOpen('lesson1', 'src');
    await usageTracker.logManualOpen('lesson1', 'src');
    await usageTracker.logManualOpen('lesson2', 'src');

    final viewLogger = RecallBoostInteractionLogger.instance;
    viewLogger.resetForTest();
    await viewLogger.logView('lesson1', 'node1', 1500);
    await viewLogger.logView('lesson1', 'node2', 500);
    await viewLogger.logView('lesson2', 'node3', 2000);

    final service = TheoryEngagementAnalyticsService(
      usageTracker: usageTracker,
      viewLogger: viewLogger,
      efficiencyService: _FakeEfficiencyService({'lesson1': 0.5}),
    );

    final stats = await service.getAllStats();
    expect(stats.length, 2);

    final lesson1 = stats.firstWhere((s) => s.lessonId == 'lesson1');
    expect(lesson1.manualOpens, 2);
    expect(lesson1.reviewViews, 1);
    expect(lesson1.successRate, closeTo(0.5, 0.0001));

    final lesson2 = stats.firstWhere((s) => s.lessonId == 'lesson2');
    expect(lesson2.manualOpens, 1);
    expect(lesson2.reviewViews, 1);
    expect(lesson2.successRate, 0);
  });
}


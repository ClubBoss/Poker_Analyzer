import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/pack_recall_stats_service.dart';
import 'package:poker_analyzer/services/review_streak_evaluator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('detects active review streak', () async {
    final service = PackRecallStatsService.instance;
    final now = DateTime.now();
    await service.recordReview('p1', now.subtract(const Duration(days: 2)));
    await service.recordReview('p1', now);

    const eval = ReviewStreakEvaluatorService();
    expect(await eval.isStreakActive('p1'), isTrue);
    expect(await eval.streakBreakDate('p1'), isNull);
  });

  test('detects broken streak and break date', () async {
    final service = PackRecallStatsService.instance;
    final now = DateTime.now();
    final fiveDaysAgo = now.subtract(const Duration(days: 5));
    await service.recordReview('p2', fiveDaysAgo);
    await service.recordReview('p2', now);

    const eval = ReviewStreakEvaluatorService();
    expect(await eval.isStreakActive('p2'), isFalse);
    final breakDate = await eval.streakBreakDate('p2');
    expect(breakDate, isNotNull);
    expect(breakDate!.difference(fiveDaysAgo), const Duration(days: 3));
  });

  test('lists packs with broken streaks', () async {
    final service = PackRecallStatsService.instance;
    final now = DateTime.now();
    await service.recordReview('p3', now.subtract(const Duration(days: 5)));
    await service.recordReview('p3', now);

    const eval = ReviewStreakEvaluatorService();
    final broken = await eval.packsWithBrokenStreaks();
    expect(broken, contains('p3'));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/decay_streak_tracker_service.dart';
import 'package:poker_analyzer/services/recall_tag_decay_summary_service.dart';
import 'package:poker_analyzer/models/tag_decay_summary.dart';

class _FakeSummaryService extends RecallTagDecaySummaryService {
  final TagDecaySummary result;
  const _FakeSummaryService(this.result);

  @override
  Future<TagDecaySummary> getSummary() async => result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('streak increments on consecutive zero-critical days', () async {
    final service = DecayStreakTrackerService(
      summary: const _FakeSummaryService(
        TagDecaySummary(
          avgDecay: 0,
          countCritical: 0,
          countWarning: 0,
          mostDecayedTags: [],
        ),
      ),
    );

    await service.evaluateToday();
    expect(await service.getCurrentStreak(), 1);

    final prefs = await SharedPreferences.getInstance();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await prefs.setString(
        'decay_streak_last_check', yesterday.toIso8601String());
    await prefs.setInt('decay_streak_count', 1);

    await service.evaluateToday();
    expect(await service.getCurrentStreak(), 2);
  });

  test('streak resets when critical decay present', () async {
    final service = DecayStreakTrackerService(
      summary: const _FakeSummaryService(
        TagDecaySummary(
          avgDecay: 0,
          countCritical: 1,
          countWarning: 0,
          mostDecayedTags: [],
        ),
      ),
    );

    await service.evaluateToday();
    expect(await service.getCurrentStreak(), 0);
  });

  test('streak starts over after gap days even if no critical decay', () async {
    final service = DecayStreakTrackerService(
      summary: const _FakeSummaryService(
        TagDecaySummary(
          avgDecay: 0,
          countCritical: 0,
          countWarning: 0,
          mostDecayedTags: [],
        ),
      ),
    );

    await service.evaluateToday();
    expect(await service.getCurrentStreak(), 1);

    final prefs = await SharedPreferences.getInstance();
    final threeAgo = DateTime.now().subtract(const Duration(days: 3));
    await prefs.setString(
        'decay_streak_last_check', threeAgo.toIso8601String());
    await prefs.setInt('decay_streak_count', 5);

    await service.evaluateToday();
    expect(await service.getCurrentStreak(), 1);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/recap_opportunity_detector.dart';
import 'package:poker_analyzer/services/tag_retention_tracker.dart';
import 'package:poker_analyzer/services/tag_mastery_service.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/services/session_streak_tracker_service.dart';
import 'package:poker_analyzer/services/app_usage_tracker.dart';
import 'package:poker_analyzer/services/booster_fatigue_guard.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeUsageTracker implements AppUsageTracker {
  Duration idle;
  FakeUsageTracker(this.idle);
  @override
  Future<void> dispose() async {}
  @override
  Future<void> init() async {}
  @override
  Future<Duration> idleDuration() async => idle;
  @override
  void didChangeAppLifecycleState(state) {}
  @override
  Future<void> markActive() async {}
}

class FakeRetentionTracker extends TagRetentionTracker {
  final List<String> list;
  FakeRetentionTracker(this.list)
      : super(
          mastery: TagMasteryService(
            logs: SessionLogService(sessions: TrainingSessionService()),
          ),
        );
  @override
  Future<List<String>> getDecayedTags({
    double threshold = 0.75,
    DateTime? now,
  }) async =>
      list;
}

class FakeStreakTrackerService implements SessionStreakTrackerService {
  final int value;
  FakeStreakTrackerService(this.value);
  @override
  Future<int> getCurrentStreak() async => value;
  @override
  Future<void> markCompletedToday() async {}
  @override
  Future<void> checkAndTriggerRewards() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('detects good recap moment', () async {
    final detector = RecapOpportunityDetector(
      retention: FakeRetentionTracker(['push']),
      usage: FakeUsageTracker(const Duration(minutes: 6)),
      streak: FakeStreakTrackerService(4),
      fatigue: BoosterFatigueGuard(loader: ({int limit = 10}) async => []),
    );
    final ok = await detector.isGoodRecapMoment();
    expect(ok, isTrue);
  });

  test('returns false when idle time short', () async {
    final detector = RecapOpportunityDetector(
      retention: FakeRetentionTracker(['push']),
      usage: FakeUsageTracker(const Duration(seconds: 30)),
      streak: FakeStreakTrackerService(4),
      fatigue: BoosterFatigueGuard(loader: ({int limit = 10}) async => []),
    );
    final ok = await detector.isGoodRecapMoment();
    expect(ok, isFalse);
  });

  test('returns false when recently prompted', () async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'recap_detector_last': now.toIso8601String(),
    });
    final detector = RecapOpportunityDetector(
      retention: FakeRetentionTracker(['push']),
      usage: FakeUsageTracker(const Duration(minutes: 6)),
      streak: FakeStreakTrackerService(4),
      fatigue: BoosterFatigueGuard(loader: ({int limit = 10}) async => []),
    );
    final ok = await detector.isGoodRecapMoment();
    expect(ok, isFalse);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/session_log.dart';
import 'package:poker_analyzer/services/goal_reengagement_service.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/services/goal_engagement_tracker.dart';
import 'package:poker_analyzer/models/goal_engagement.dart';

class _FakeLogService extends SessionLogService {
  final List<SessionLog> list;
  _FakeLogService(this.list) : super(sessions: TrainingSessionService());
  @override
  Future<void> load() async {}
  @override
  List<SessionLog> get logs => list;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('pickReengagementGoal returns stale goal', () async {
    final now = DateTime.now();
    final logs = [
      SessionLog(
        tags: const [],
        sessionId: '1',
        templateId: 'cbet_ip',
        startedAt: now.subtract(const Duration(days: 10)),
        completedAt: now.subtract(const Duration(days: 10)),
        correctCount: 1,
        mistakeCount: 0,
      ),
      SessionLog(
        tags: const [],
        sessionId: '2',
        templateId: 'open_fold_lj_mtt',
        startedAt: now.subtract(const Duration(days: 1)),
        completedAt: now.subtract(const Duration(days: 1)),
        correctCount: 1,
        mistakeCount: 0,
      ),
    ];
    final service = GoalReengagementService(logs: _FakeLogService(logs));
    await GoalEngagementTracker.instance.log(
      GoalEngagement(
        tag: 'cbet',
        action: 'start',
        timestamp: now.subtract(const Duration(days: 10)),
      ),
    );
    final goal = await service.pickReengagementGoal();
    expect(goal?.tag, 'cbet');
  });

  test('dismissed goal is skipped after 3 times', () async {
    final now = DateTime.now();
    final logs = [
      SessionLog(
        tags: const [],
        sessionId: '1',
        templateId: 'cbet_ip',
        startedAt: now.subtract(const Duration(days: 10)),
        completedAt: now.subtract(const Duration(days: 10)),
        correctCount: 1,
        mistakeCount: 0,
      ),
    ];
    final service = GoalReengagementService(logs: _FakeLogService(logs));
    for (int i = 0; i < 3; i++) {
      await service.markDismissed('cbet');
    }
    final goal = await service.pickReengagementGoal();
    expect(goal, isNull);
  });
}

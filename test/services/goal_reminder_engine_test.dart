import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/session_log.dart';
import 'package:poker_analyzer/models/training_goal.dart';
import 'package:poker_analyzer/models/training_result.dart';
import 'package:poker_analyzer/services/goal_reminder_engine.dart';
import 'package:poker_analyzer/services/goal_suggestion_service.dart';
import 'package:poker_analyzer/services/smart_goal_tracking_service.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/tag_mastery_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/services/pack_library_loader_service.dart';
import 'package:poker_analyzer/services/smart_recommender_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLogService extends SessionLogService {
  final List<SessionLog> list;
  _FakeLogService(this.list) : super(sessions: TrainingSessionService());

  @override
  Future<void> load() async {}

  @override
  List<SessionLog> get logs => list;

  @override
  Future<UserProgress> getUserProgress() async {
    await PackLibraryLoaderService.instance.loadLibrary();
    final library = {
      for (final t in PackLibraryLoaderService.instance.library) t.id: t,
    };
    final history = <TrainingResult>[];
    for (final log in list) {
      final tpl = library[log.templateId];
      final tags = tpl?.tags ?? const <String>[];
      final total = log.correctCount + log.mistakeCount;
      final acc = total > 0 ? log.correctCount / total * 100 : 0.0;
      history.add(
        TrainingResult(
          date: log.completedAt,
          total: total,
          correct: log.correctCount,
          accuracy: acc,
          tags: tags,
        ),
      );
    }
    return UserProgress(history: history);
  }
}

class _FakeMasteryService extends TagMasteryService {
  final Map<String, double> map;
  _FakeMasteryService(this.map, SessionLogService logs) : super(logs: logs);

  @override
  Future<Map<String, double>> computeMastery({bool force = false}) async => map;
}

class _FakeSuggestionService extends GoalSuggestionService {
  final List<TrainingGoal> goals;
  _FakeSuggestionService({
    required TagMasteryService mastery,
    required this.goals,
  }) : super(mastery: mastery);

  @override
  Future<List<TrainingGoal>> suggestGoals({
    required UserProgress progress,
  }) async =>
      goals;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('getStaleGoals returns goals inactive for more than 3 days', () async {
    final now = DateTime.now();
    final logs = _FakeLogService([
      SessionLog(
        tags: const [],
        sessionId: '1',
        templateId: 'cbet_ip',
        startedAt: now.subtract(const Duration(days: 5)),
        completedAt: now.subtract(const Duration(days: 5)),
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
    ]);
    final mastery = _FakeMasteryService({}, logs);
    final suggestions = _FakeSuggestionService(
      mastery: mastery,
      goals: const [
        TrainingGoal('CBet goal', tag: 'cbet'),
        TrainingGoal('OpenFold goal', tag: 'openfold'),
      ],
    );
    final tracker = SmartGoalTrackingService(logs: logs);
    final engine = GoalReminderEngine(
      suggestions: suggestions,
      logs: logs,
      tracker: tracker,
    );
    final stale = await engine.getStaleGoals();
    expect(stale.length, 1);
    expect(stale.first.tag, 'cbet');
  });
}

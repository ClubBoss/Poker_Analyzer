import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/training_result.dart';
import 'package:poker_analyzer/services/goal_suggestion_service.dart';
import 'package:poker_analyzer/services/tag_mastery_service.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/models/session_log.dart';

class _FakeLogService extends SessionLogService {
  _FakeLogService() : super(sessions: TrainingSessionService());
  @override
  Future<void> load() async {}
  @override
  List<SessionLog> get logs => const [];
}

class _FakeMasteryService extends TagMasteryService {
  final Map<String, double> map;
  _FakeMasteryService(this.map) : super(logs: _FakeLogService());

  @override
  Future<Map<String, double>> computeMastery({bool force = false}) async => map;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('suggestGoals returns prioritized goals', () async {
    final progress = UserProgress(
      history: [
        TrainingResult(
          date: DateTime.now(),
          total: 10,
          correct: 5,
          accuracy: 50,
          tags: const ['sbvsbb'],
        ),
        TrainingResult(
          date: DateTime.now(),
          total: 8,
          correct: 6,
          accuracy: 75,
          tags: const ['openfold'],
        ),
        TrainingResult(
          date: DateTime.now(),
          total: 5,
          correct: 5,
          accuracy: 100,
          tags: const ['strong'],
        ),
      ],
    );

    final mastery = _FakeMasteryService({
      'sbvsbb': 0.3,
      'openfold': 0.6,
      'strong': 0.9,
    });

    final service = GoalSuggestionService(mastery: mastery);
    final goals = await service.suggestGoals(progress: progress);

    expect(goals.length, 2);
    expect(goals.first.title, contains('SB vs BB'));
    expect(goals.last.title, contains('open/fold'));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/session_log.dart';
import 'package:poker_analyzer/services/learning_path_gatekeeper_service.dart';
import 'package:poker_analyzer/services/training_path_progress_service_v2.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/services/learning_path_registry_service.dart';
import 'package:poker_analyzer/services/tag_mastery_service.dart';

class _FakeLogService extends SessionLogService {
  List<SessionLog> entries;
  _FakeLogService(this.entries) : super(sessions: TrainingSessionService());
  @override
  Future<void> load() async {}
  @override
  List<SessionLog> get logs => List.unmodifiable(entries);
}

class _FakeMasteryService extends TagMasteryService {
  final Map<String, double> _map;
  _FakeMasteryService(this._map)
      : super(logs: SessionLogService(sessions: TrainingSessionService()));

  @override
  Future<Map<String, double>> computeMastery({bool force = false}) async => _map;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LearningPathRegistryService.instance.loadAll();
  });

  test('stage unlock respects mastery threshold', () async {
    final logs = [
      SessionLog(
        sessionId: '1',
        templateId: 'pack1',
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        correctCount: 10,
        mistakeCount: 0,
      ),
    ];
    final progress = TrainingPathProgressServiceV2(logs: _FakeLogService(logs));
    await progress.loadProgress('sample');
    await progress.markStageCompleted('s1', 100);

    final mastery = _FakeMasteryService({'advanced': 0.5});
    final gatekeeper = LearningPathGatekeeperService(
      progress: progress,
      mastery: mastery,
      masteryThreshold: 0.6,
    );

    await gatekeeper.updateStageUnlocks('sample');
    expect(gatekeeper.isStageUnlocked('s2'), isTrue);
  });
}

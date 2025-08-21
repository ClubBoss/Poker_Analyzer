import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/session_log.dart';
import 'package:poker_analyzer/services/learning_path_gatekeeper_service.dart';
import 'package:poker_analyzer/services/learning_track_progress_service.dart';
import 'package:poker_analyzer/services/training_path_progress_service_v2.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/services/learning_path_registry_service.dart';
import 'package:poker_analyzer/models/learning_track_progress_model.dart';
import 'package:poker_analyzer/services/tag_mastery_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLogService extends SessionLogService {
  final List<SessionLog> entries;
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
  Future<Map<String, double>> computeMastery({bool force = false}) async =>
      _map;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LearningPathRegistryService.instance.loadAll();
  });

  test('progress model marks completed and unlocked stages', () async {
    final logs = [
      SessionLog(
        tags: const [],
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

    final gatekeeper = LearningPathGatekeeperService(
      progress: progress,
      mastery: _FakeMasteryService(const {}),
    );
    await gatekeeper.updateStageUnlocks('sample');

    final svc = LearningTrackProgressService(
      progress: progress,
      gatekeeper: gatekeeper,
    );
    final model = await svc.build('sample');
    expect(model.statusFor('s1')?.status, StageStatus.completed);
    expect(model.statusFor('s2')?.status, StageStatus.unlocked);
  });

  test('advanceToNextStage marks stage completed', () async {
    final logs = [
      SessionLog(
        tags: const [],
        sessionId: '1',
        templateId: 'pack1',
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        correctCount: 8,
        mistakeCount: 2,
      ),
    ];
    final progress = TrainingPathProgressServiceV2(logs: _FakeLogService(logs));
    await progress.loadProgress('sample');

    final gatekeeper = LearningPathGatekeeperService(
      progress: progress,
      mastery: _FakeMasteryService(const {}),
    );
    await gatekeeper.updateStageUnlocks('sample');

    final svc = LearningTrackProgressService(
      progress: progress,
      gatekeeper: gatekeeper,
    );
    await svc.build('sample');
    await svc.advanceToNextStage('s1');
    final model = await svc.build('sample');
    expect(model.statusFor('s1')?.status, StageStatus.completed);
    expect(gatekeeper.isStageUnlocked('s2'), isTrue);
  });
}

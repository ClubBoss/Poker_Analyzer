import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/session_log.dart';
import 'package:poker_analyzer/services/training_path_progress_service_v2.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/services/learning_path_registry_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLogService extends SessionLogService {
  List<SessionLog> entries;
  _FakeLogService(this.entries) : super(sessions: TrainingSessionService());

  @override
  Future<void> load() async {}

  @override
  List<SessionLog> get logs => List.unmodifiable(entries);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LearningPathRegistryService.instance.loadAll();
  });

  test('stage unlocks after completion', () async {
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
    final svc = TrainingPathProgressServiceV2(logs: _FakeLogService(logs));
    await svc.loadProgress('sample');
    expect(svc.isStageUnlocked('s1'), isTrue);
    expect(svc.isStageUnlocked('s2'), isFalse);

    await svc.markStageCompleted('s1', 80);
    expect(svc.isStageUnlocked('s2'), isTrue);
    expect(svc.getStageAccuracy('s1'), closeTo(80, 0.1));
  });

  test('stage remains locked when requirements unmet', () async {
    final logs = [
      SessionLog(
        tags: const [],
        sessionId: '1',
        templateId: 'pack1',
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        correctCount: 4,
        mistakeCount: 6,
      ),
    ];
    final svc = TrainingPathProgressServiceV2(logs: _FakeLogService(logs));
    await svc.loadProgress('sample');
    await svc.markStageCompleted('s1', 40);
    expect(svc.isStageUnlocked('s2'), isFalse);
  });
}

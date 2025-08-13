import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/session_log.dart';
import 'package:poker_analyzer/services/learning_path_stats_service.dart';
import 'package:poker_analyzer/services/training_path_progress_service_v2.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/services/learning_path_registry_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLogService extends SessionLogService {
  final List<SessionLog> entries;
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

  test('compute stats with section and unlockAfter rules', () async {
    final logs = [
      SessionLog(
        tags: const [],
        sessionId: '1',
        templateId: 'pack1',
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        correctCount: 1,
        mistakeCount: 0,
      ),
    ];
    final progress = TrainingPathProgressServiceV2(logs: _FakeLogService(logs));
    await progress.loadProgress('unlock_after');

    final template =
        LearningPathRegistryService.instance.findById('unlock_after')!;
    final svc = LearningPathStatsService(progress: progress);

    var stats = svc.computeStats(template);
    expect(stats.completedStages, 0);
    expect(stats.lockedStageIds, containsAll(['ua2', 'ua3']));

    await progress.markStageCompleted('ua1', 100);
    stats = svc.computeStats(template);
    expect(stats.completedStages, 1);
    expect(stats.lockedStageIds, contains('ua3'));
    expect(stats.lockedStageIds.contains('ua2'), isFalse);

    await progress.markStageCompleted('ua2', 100);
    stats = svc.computeStats(template);
    expect(stats.completedStages, 2);
    expect(stats.lockedStageIds, isEmpty);
  });
}

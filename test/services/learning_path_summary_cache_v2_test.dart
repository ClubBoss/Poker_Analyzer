import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/session_log.dart';
import 'package:poker_analyzer/services/learning_path_registry_service.dart';
import 'package:poker_analyzer/services/learning_path_summary_cache_v2.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_path_progress_service_v2.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
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

  test('summary computes progress for sample path', () async {
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
    await progress.markStageCompleted('s1', 80);

    final cache = LearningPathSummaryCache(progress: progress);
    await cache.refresh();
    final summary = cache.summaryById('sample');
    expect(summary, isNotNull);
    expect(summary!.completedStages, 1);
    expect(summary.totalStages, 2);
    expect(summary.percentComplete, closeTo(0.5, 0.01));
    expect(summary.unlockedStageCount, 2);
    expect(summary.isFinished, isFalse);
    expect(summary.nextStageToTrain?.id, 's2');
  });
}

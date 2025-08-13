import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/session_log.dart';
import 'package:poker_analyzer/services/learning_path_progress_engine.dart';
import 'package:poker_analyzer/services/learning_path_registry_service.dart';
import 'package:poker_analyzer/services/learning_path_track_library_service.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
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
    await LearningPathTrackLibraryService.instance.reload();
  });

  test('computes path and track progress', () async {
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
      SessionLog(
        tags: const [],
        sessionId: '2',
        templateId: 'pack2',
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        correctCount: 5,
        mistakeCount: 0,
      ),
    ];

    final engine = LearningPathProgressEngine(
      logs: _FakeLogService(logs),
      packSizeLoader: (id) async => id == 'pack1' ? 10 : 20,
    );

    final pathProg = await engine.getPathProgress('sample');
    expect(pathProg, closeTo(0.5, 0.01));

    final trackProg = await engine.getTrackProgress('fundamentals');
    expect(trackProg, closeTo(0.5, 0.01));

    final all = await engine.getAllPathProgress();
    expect(all['sample'], closeTo(0.5, 0.01));
  });
}

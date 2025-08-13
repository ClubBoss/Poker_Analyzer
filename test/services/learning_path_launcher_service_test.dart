import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/models/session_log.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/services/learning_path_launcher_service.dart';
import 'package:poker_analyzer/services/learning_path_summary_cache_v2.dart';
import 'package:poker_analyzer/services/pack_library_service.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_path_progress_service_v2.dart';
import 'package:poker_analyzer/services/training_session_launcher.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLogService extends SessionLogService {
  _FakeLogService() : super(sessions: TrainingSessionService());
  @override
  Future<void> load() async {}
  @override
  List<SessionLog> get logs => [];
}

class _FakeCache extends LearningPathSummaryCache {
  final LearningPathSummary? summary;
  _FakeCache(this.summary)
      : super(progress: TrainingPathProgressServiceV2(logs: _FakeLogService()));
  @override
  Future<void> refresh() async {}
  @override
  LearningPathSummary? summaryById(String id) => summary;
}

class _FakeLibrary implements PackLibraryService {
  final Map<String, TrainingPackTemplateV2> packs;
  _FakeLibrary(this.packs);
  @override
  Future<TrainingPackTemplateV2?> recommendedStarter() async => null;
  @override
  Future<TrainingPackTemplateV2?> getById(String id) async => packs[id];
  @override
  Future<TrainingPackTemplateV2?> findByTag(String tag) async =>
      packs.values.firstWhereOrNull((p) => p.tags.contains(tag));
  @override
  Future<List<String>> findBoosterCandidates(String tag) async => const [];
}

class _FakeLauncher extends TrainingSessionLauncher {
  TrainingPackTemplateV2? launched;
  _FakeLauncher() : super();
  @override
  Future<void> launch(TrainingPackTemplateV2 template) async {
    launched = template;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('launchNextStage starts next pack', (tester) async {
    const stage = LearningPathStageModel(
      id: 's',
      title: 'Stage',
      description: '',
      packId: 'p1',
      requiredAccuracy: 0,
      minHands: 0,
    );
    const summary = LearningPathSummary(
      id: 'path',
      title: '',
      completedStages: 0,
      totalStages: 1,
      percentComplete: 0,
      unlockedStageCount: 1,
      isFinished: false,
      nextStageToTrain: stage,
    );
    final cache = _FakeCache(summary);
    final library = _FakeLibrary({
      'p1': TrainingPackTemplateV2(
        id: 'p1',
        name: 'Pack',
        trainingType: TrainingType.pushFold,
        gameType: GameType.tournament,
        spotCount: 0,
        spots: const [],
        created: DateTime.now(),
        positions: const [],
      ),
    });
    final launcher = _FakeLauncher();

    final key = GlobalKey();
    await tester
        .pumpWidget(MaterialApp(home: Scaffold(body: Container(key: key))));
    final ctx = key.currentContext!;

    final service = LearningPathLauncherService(
      cache: cache,
      library: library,
      launcher: launcher,
    );
    await service.launchNextStage('path', ctx);
    expect(launcher.launched?.id, 'p1');
  });

  testWidgets('shows snackbar when no stage available', (tester) async {
    const summary = LearningPathSummary(
      id: 'path',
      title: '',
      completedStages: 1,
      totalStages: 1,
      percentComplete: 1,
      unlockedStageCount: 1,
      isFinished: true,
      nextStageToTrain: null,
    );
    final cache = _FakeCache(summary);
    final library = _FakeLibrary({});
    final launcher = _FakeLauncher();

    final key = GlobalKey();
    await tester
        .pumpWidget(MaterialApp(home: Scaffold(body: Container(key: key))));
    final ctx = key.currentContext!;

    final service = LearningPathLauncherService(
      cache: cache,
      library: library,
      launcher: launcher,
    );
    await service.launchNextStage('path', ctx);
    await tester.pump();
    expect(launcher.launched, isNull);
    expect(find.byType(SnackBar), findsOneWidget);
  });
}

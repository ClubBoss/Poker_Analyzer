import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/models/stage_type.dart';
import 'package:poker_analyzer/models/theory_pack_model.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/services/learning_path_stage_launcher.dart';
import 'package:poker_analyzer/services/pack_library_service.dart';
import 'package:poker_analyzer/services/theory_pack_library_service.dart';
import 'package:poker_analyzer/services/training_session_launcher.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/screens/theory_pack_reader_screen.dart';
import 'package:poker_analyzer/services/user_action_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePackLibrary implements PackLibraryService {
  final Map<String, TrainingPackTemplateV2> packs;
  _FakePackLibrary(this.packs);
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
  Future<void> launch(TrainingPackTemplateV2 template,
      {int startIndex = 0}) async {
    launched = template;
  }
}

class _FakeTheoryLibrary implements TheoryPackLibraryService {
  final Map<String, TheoryPackModel> packs;
  _FakeTheoryLibrary(this.packs);
  @override
  List<TheoryPackModel> get all => packs.values.toList();
  @override
  TheoryPackModel? getById(String id) => packs[id];
  @override
  Future<void> loadAll() async {}
  @override
  Future<void> reload() async {}
}

TrainingPackTemplateV2 _tpl(String id) {
  return TrainingPackTemplateV2(
    id: id,
    name: id,
    trainingType: TrainingType.pushFold,
    gameType: GameType.tournament,
    spots: const [TrainingPackSpot(id: 's')],
    spotCount: 1,
    created: DateTime.now(),
    positions: const [],
  );
}

TheoryPackModel _theory(String id) {
  return TheoryPackModel(id: id, title: id, sections: const [], tags: const []);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('launch practice stage starts session', (tester) async {
    final library = _FakePackLibrary({'p1': _tpl('p1')});
    final launcher = _FakeLauncher();
    final service = LearningPathStageLauncher(
      library: library,
      theoryLibrary: _FakeTheoryLibrary(const {}),
      launcher: launcher,
    );
    const stage = LearningPathStageModel(
      id: 's',
      title: 'S',
      description: '',
      packId: 'p1',
      requiredAccuracy: 0,
      minHands: 0,
      type: StageType.practice,
    );
    final key = GlobalKey();
    await tester
        .pumpWidget(MaterialApp(home: Scaffold(body: Container(key: key))));
    await service.launch(key.currentContext!, stage);
    expect(launcher.launched?.id, 'p1');
    expect(UserActionLogger.instance.events.last['event'], 'stage_opened');
  });

  testWidgets('launch theory stage opens reader', (tester) async {
    final theory = _theory('t1');
    final service = LearningPathStageLauncher(
      library: _FakePackLibrary(const {}),
      theoryLibrary: _FakeTheoryLibrary({'t1': theory}),
    );
    const stage = LearningPathStageModel(
      id: 's',
      title: 'S',
      description: '',
      packId: 'p',
      theoryPackId: 't1',
      requiredAccuracy: 0,
      minHands: 0,
      type: StageType.theory,
    );
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
        navigatorKey: GlobalKey(), home: Scaffold(body: Container(key: key))));
    await service.launch(key.currentContext!, stage);
    await tester.pumpAndSettle();
    expect(find.byType(TheoryPackReaderScreen), findsOneWidget);
  });

  testWidgets('launch booster stage uses booster id', (tester) async {
    final booster = _theory('b1');
    final service = LearningPathStageLauncher(
      library: _FakePackLibrary(const {}),
      theoryLibrary: _FakeTheoryLibrary({'b1': booster}),
    );
    const stage = LearningPathStageModel(
      id: 's',
      title: 'S',
      description: '',
      packId: 'p',
      boosterTheoryPackIds: ['b1'],
      requiredAccuracy: 0,
      minHands: 0,
      type: StageType.booster,
    );
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
        navigatorKey: GlobalKey(), home: Scaffold(body: Container(key: key))));
    await service.launch(key.currentContext!, stage);
    await tester.pumpAndSettle();
    expect(find.byType(TheoryPackReaderScreen), findsOneWidget);
  });
}

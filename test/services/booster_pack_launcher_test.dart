import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/booster_pack_launcher.dart';
import 'package:poker_analyzer/services/skill_map_booster_recommender.dart';
import 'package:poker_analyzer/services/tag_mastery_service.dart';
import 'package:poker_analyzer/services/pack_library_service.dart';
import 'package:poker_analyzer/services/training_session_launcher.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';

class _FakeMasteryService extends TagMasteryService {
  final Map<String, double> _map;
  _FakeMasteryService(this._map)
      : super(logs: SessionLogService(sessions: TrainingSessionService()));

  @override
  Future<Map<String, double>> computeMastery({bool force = false}) async =>
      _map;
}

class _FakeLibrary implements PackLibraryService {
  final List<TrainingPackTemplateV2> packs;
  _FakeLibrary(this.packs);
  @override
  Future<TrainingPackTemplateV2?> recommendedStarter() async => null;
  @override
  Future<TrainingPackTemplateV2?> getById(String id) async =>
      packs.firstWhereOrNull((p) => p.id == id);
  @override
  Future<TrainingPackTemplateV2?> findByTag(String tag) async =>
      packs.firstWhereOrNull((p) => p.tags.contains(tag));
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

TrainingPackTemplateV2 tpl({required String id, required List<String> tags}) {
  return TrainingPackTemplateV2(
    id: id,
    name: id,
    trainingType: TrainingType.pushFold,
    gameType: GameType.tournament,
    tags: tags,
    spots: const [],
    spotCount: 0,
    created: DateTime.now(),
    positions: const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('launches first matching booster', (tester) async {
    final mastery = _FakeMasteryService({'icm': 0.2});
    final library = _FakeLibrary([
      tpl(id: 'a', tags: ['icm']),
      tpl(id: 'b', tags: ['cbet']),
    ]);
    final launcher = _FakeLauncher();
    final service = BoosterPackLauncher(
      mastery: mastery,
      library: library,
      launcher: launcher,
      recommender: SkillMapBoosterRecommender(),
    );
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Container(key: key)),
      ),
    );
    await service.launchBooster(key.currentContext!);
    expect(launcher.launched?.id, 'a');
  });

  testWidgets('shows snackbar when no pack', (tester) async {
    final mastery = _FakeMasteryService({'icm': 0.2});
    final library = _FakeLibrary([]);
    final launcher = _FakeLauncher();
    final service = BoosterPackLauncher(
      mastery: mastery,
      library: library,
      launcher: launcher,
      recommender: SkillMapBoosterRecommender(),
    );
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Container(key: key)),
      ),
    );
    await service.launchBooster(key.currentContext!);
    await tester.pump();
    expect(launcher.launched, isNull);
    expect(find.byType(SnackBar), findsOneWidget);
  });
}

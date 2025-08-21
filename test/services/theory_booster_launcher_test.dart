import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/theory_booster_launcher.dart';
import 'package:poker_analyzer/services/tag_mastery_service.dart';
import 'package:poker_analyzer/services/training_session_launcher.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/core/training/library/training_pack_library_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:collection/collection.dart';

class _FakeMasteryService extends TagMasteryService {
  final Map<String, double> _map;
  _FakeMasteryService(this._map)
      : super(logs: SessionLogService(sessions: TrainingSessionService()));

  @override
  Future<Map<String, double>> computeMastery({bool force = false}) async =>
      _map;
}

class _FakeLauncher extends TrainingSessionLauncher {
  TrainingPackTemplateV2? launched;
  _FakeLauncher();
  @override
  Future<void> launch(
    TrainingPackTemplateV2 template, {
    int startIndex = 0,
  }) async {
    launched = template;
  }
}

class _FakeLibrary implements TrainingPackLibraryV2 {
  final List<TrainingPackTemplateV2> _packs;
  _FakeLibrary(this._packs);

  @override
  List<TrainingPackTemplateV2> get packs => List.unmodifiable(_packs);

  @override
  void addPack(TrainingPackTemplateV2 pack) => _packs.add(pack);

  @override
  void clear() => _packs.clear();

  @override
  List<TrainingPackTemplateV2> filterBy({
    GameType? gameType,
    TrainingType? type,
    List<String>? tags,
  }) {
    return [
      for (final p in _packs)
        if ((gameType == null || p.gameType == gameType) &&
            (type == null || p.trainingType == type) &&
            (tags == null || tags.every((t) => p.tags.contains(t))))
          p,
    ];
  }

  @override
  TrainingPackTemplateV2? getById(String id) =>
      _packs.firstWhereOrNull((p) => p.id == id);

  @override
  Future<void> loadFromFolder([
    String path = TrainingPackLibraryV2.packsDir,
  ]) async {}

  @override
  Future<void> reload() async {}
}

TrainingPackTemplateV2 tpl({
  required String id,
  required List<String> tags,
  int spots = 6,
}) {
  return TrainingPackTemplateV2(
    id: id,
    name: id,
    trainingType: TrainingType.pushFold,
    gameType: GameType.tournament,
    tags: tags,
    spotCount: spots,
    spots: const [],
    created: DateTime.now(),
    positions: const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('picks pack with lowest mastery', () async {
    final mastery = _FakeMasteryService({'icm': 0.2, 'cbet': 0.8});
    final library = _FakeLibrary([
      tpl(id: 'a', tags: ['icm'], spots: 6),
      tpl(id: 'b', tags: ['cbet'], spots: 6),
    ]);
    final launcher = _FakeLauncher();
    final service = TheoryBoosterLauncher(
      mastery: mastery,
      library: library,
      launcher: launcher,
    );
    final lesson = TheoryMiniLessonNode(
      id: 'l1',
      title: '',
      content: '',
      tags: const ['icm', 'cbet'],
      nextIds: const [],
    );
    final pack = await service.launchBoosterFor(lesson);
    expect(pack?.id, 'a');
    expect(launcher.launched?.id, 'a');
  });

  test('returns null when no match', () async {
    final mastery = _FakeMasteryService({'icm': 0.2});
    final library = _FakeLibrary([
      tpl(id: 'a', tags: ['other'], spots: 6),
    ]);
    final launcher = _FakeLauncher();
    final service = TheoryBoosterLauncher(
      mastery: mastery,
      library: library,
      launcher: launcher,
    );
    final lesson = TheoryMiniLessonNode(
      id: 'l1',
      title: '',
      content: '',
      tags: const ['icm'],
      nextIds: const [],
    );
    final pack = await service.launchBoosterFor(lesson);
    expect(pack, isNull);
    expect(launcher.launched, isNull);
  });

  test('prefers moderate length packs', () async {
    final mastery = _FakeMasteryService({'icm': 0.5});
    final library = _FakeLibrary([
      tpl(id: 'short', tags: ['icm'], spots: 4),
      tpl(id: 'mod', tags: ['icm'], spots: 8),
    ]);
    final launcher = _FakeLauncher();
    final service = TheoryBoosterLauncher(
      mastery: mastery,
      library: library,
      launcher: launcher,
    );
    final lesson = TheoryMiniLessonNode(
      id: 'l1',
      title: '',
      content: '',
      tags: const ['icm'],
      nextIds: const [],
    );
    final pack = await service.launchBoosterFor(lesson);
    expect(pack?.id, 'mod');
    expect(launcher.launched?.id, 'mod');
  });
}

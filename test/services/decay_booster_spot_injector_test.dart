import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/training_history_entry_v2.dart';
import 'package:poker_analyzer/core/training/library/training_pack_library_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/services/decay_booster_spot_injector.dart';
import 'package:poker_analyzer/services/booster_queue_service.dart';
import 'package:poker_analyzer/services/theory_tag_decay_tracker.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';

class _FakeDecay extends TheoryTagDecayTracker {
  final Map<String, double> scores;
  _FakeDecay(this.scores);
  @override
  Future<Map<String, double>> computeDecayScores({DateTime? now}) async =>
      scores;
}

class _FakeLessonLibrary implements MiniLessonLibraryService {
  final List<TheoryMiniLessonNode> lessons;
  _FakeLessonLibrary(this.lessons);

  @override
  List<TheoryMiniLessonNode> get all => lessons;

  @override
  Future<void> loadAll() async {}

  @override
  Future<void> reload() async {}

  @override
  TheoryMiniLessonNode? getById(String id) =>
      lessons.firstWhereOrNull((l) => l.id == id);

  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) => [
    for (final l in lessons)
      if (l.tags.any(tags.contains)) l,
  ];

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) =>
      findByTags(tags.toList());
}

class _FakePackLibrary implements TrainingPackLibraryV2 {
  final List<TrainingPackTemplateV2> _packs;
  _FakePackLibrary(this._packs);

  @override
  List<TrainingPackTemplateV2> get packs => List.unmodifiable(_packs);

  @override
  void addPack(TrainingPackTemplateV2 pack) => _packs.add(pack);

  @override
  void clear() => _packs.clear();

  @override
  TrainingPackTemplateV2? getById(String id) =>
      _packs.firstWhereOrNull((p) => p.id == id);

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
  Future<void> loadFromFolder([
    String path = TrainingPackLibraryV2.packsDir,
  ]) async {}

  @override
  Future<void> reload() async {}
}

TrainingPackTemplateV2 _pack(String id, String tag, String spotId) {
  return TrainingPackTemplateV2(
    id: id,
    name: id,
    trainingType: TrainingType.pushFold,
    tags: [tag],
    spots: [
      TrainingPackSpot(id: spotId, tags: [tag]),
    ],
    spotCount: 1,
  );
}

TrainingHistoryEntryV2 _hist(String packId) => TrainingHistoryEntryV2(
  timestamp: DateTime.now(),
  tags: const [],
  packId: packId,
  type: TrainingType.pushFold,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    BoosterQueueService.instance.clear();
  });

  test('queues spots from recent packs', () async {
    final pack = _pack('p1', 'push', 's1');
    final injector = DecayBoosterSpotInjector(
      decay: _FakeDecay({'push': 60}),
      lessons: _FakeLessonLibrary(const []),
      library: _FakePackLibrary([pack]),
      historyLoader: ({int limit = 20}) async => [_hist('p1')],
    );

    await injector.inject();

    final q = BoosterQueueService.instance.getQueue();
    expect(q.map((e) => e.id), ['s1']);
  });

  test('falls back to linked lesson packs', () async {
    final pack = _pack('p1', 'push', 's1');
    final lesson = const TheoryMiniLessonNode(
      id: 'l1',
      title: 't',
      content: '',
      tags: ['push'],
      linkedPackIds: ['p1'],
      nextIds: [],
    );
    final injector = DecayBoosterSpotInjector(
      decay: _FakeDecay({'push': 70}),
      lessons: _FakeLessonLibrary([lesson]),
      library: _FakePackLibrary([pack]),
      historyLoader: ({int limit = 20}) async => [],
    );

    await injector.inject();

    final q = BoosterQueueService.instance.getQueue();
    expect(q.map((e) => e.id), ['s1']);
  });
}

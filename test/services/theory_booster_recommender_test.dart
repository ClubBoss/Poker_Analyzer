import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/theory_booster_recommender.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/mistake_tag_history_entry.dart';
import 'package:poker_analyzer/models/mistake_tag.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/services/booster_library_service.dart';
import 'package:collection/collection.dart';

TrainingPackTemplateV2 booster(String id, String tag) {
  return TrainingPackTemplateV2(
    id: id,
    name: id,
    trainingType: TrainingType.pushFold,
    gameType: GameType.tournament,
    tags: [tag],
    spots: const [],
    spotCount: 0,
    created: DateTime.now(),
    positions: const [],
    meta: {'type': 'booster', 'tag': tag},
  );
}

class _FakeLibrary implements BoosterLibraryService {
  final List<TrainingPackTemplateV2> boosters;
  _FakeLibrary(this.boosters);
  @override
  Future<void> loadAll({int limit = 500}) async {}
  @override
  List<TrainingPackTemplateV2> get all => boosters;
  @override
  TrainingPackTemplateV2? getById(String id) =>
      boosters.firstWhereOrNull((b) => b.id == id);
  @override
  List<TrainingPackTemplateV2> findByTag(String tag) {
    return [
      for (final b in boosters)
        if (b.meta['tag'] == tag) b,
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('recommends booster matching lesson tag and ev impact', () async {
    final lesson = TheoryMiniLessonNode(
      id: 'l1',
      title: '',
      content: '',
      tags: ['btn overfold'],
    );

    final history = [
      MistakeTagHistoryEntry(
        timestamp: DateTime.now(),
        packId: 'p1',
        spotId: 's1',
        tags: const [MistakeTag.overfoldBtn],
        evDiff: -10,
      ),
    ];

    final library = _FakeLibrary([
      booster('b1', 'btn overfold'),
      booster('b2', 'loose call'),
    ]);

    final rec = await TheoryBoosterRecommender(
      library: library,
    ).recommend(lesson, recentMistakes: history);

    expect(rec, isNotNull);
    expect(rec!.boosterId, 'b1');
    expect(rec.reasonTag, 'btn overfold');
    expect(rec.priority, greaterThan(0));
    expect(rec.origin, 'lesson');
  });

  test('returns null when no booster matches', () async {
    final lesson = TheoryMiniLessonNode(
      id: 'l1',
      title: '',
      content: '',
      tags: ['icm'],
    );
    final library = _FakeLibrary([booster('b1', 'push')]);
    final rec = await TheoryBoosterRecommender(
      library: library,
    ).recommend(lesson, recentMistakes: const []);
    expect(rec, isNull);
  });
}

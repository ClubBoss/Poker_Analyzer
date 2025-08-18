import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/theory_lesson_cluster.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/services/smart_theory_booster_bridge.dart';
import 'package:poker_analyzer/services/theory_lesson_tag_clusterer.dart';
import 'package:poker_analyzer/services/theory_cluster_summary_service.dart';
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
  List<TrainingPackTemplateV2> findByTag(String tag) => [];
}

class _StubClusterer extends TheoryLessonTagClusterer {
  final List<TheoryLessonCluster> clusters;
  _StubClusterer(this.clusters);
  @override
  Future<List<TheoryLessonCluster>> clusterLessons() async => clusters;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('recommend links lessons to boosters by tag', () async {
    const lesson = TheoryMiniLessonNode(
      id: 'l1',
      title: '',
      content: '',
      tags: ['push'],
    );
    final cluster = TheoryLessonCluster(
      lessons: const [lesson],
      tags: const {'push'},
    );
    final library = _FakeLibrary([booster('b1', 'push')]);
    final bridge = SmartTheoryBoosterBridge(
      library: library,
      clusterer: _StubClusterer([cluster]),
      summaryService: TheoryClusterSummaryService(),
    );

    final recs = await bridge.recommend(const [lesson]);
    expect(recs.length, 1);
    expect(recs.first.boosterId, 'b1');
    expect(recs.first.origin, 'weakTheory');
  });

  test('falls back to cluster tags when lesson has none', () async {
    const l1 = TheoryMiniLessonNode(id: 'a', title: '', content: '', tags: []);
    const l2 = TheoryMiniLessonNode(
      id: 'b',
      title: '',
      content: '',
      tags: ['call'],
    );
    final cluster = TheoryLessonCluster(
      lessons: const [l1, l2],
      tags: const {'call'},
    );
    final library = _FakeLibrary([booster('b2', 'call')]);
    final bridge = SmartTheoryBoosterBridge(
      library: library,
      clusterer: _StubClusterer([cluster]),
      summaryService: TheoryClusterSummaryService(),
    );

    final recs = await bridge.recommend(const [l1]);
    expect(recs.length, 1);
    expect(recs.first.boosterId, 'b2');
  });
}

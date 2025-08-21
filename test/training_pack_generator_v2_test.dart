import 'package:test/test.dart';
import 'package:poker_analyzer/services/training_pack_generator_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/services/weakness_cluster_engine_v2.dart';
import 'package:poker_analyzer/repositories/training_pack_repository.dart';

class _FakeRepo extends TrainingPackRepository {
  final Map<String, List<TrainingPackSpot>> map;
  const _FakeRepo(this.map);

  @override
  Future<List<TrainingPackSpot>> getSpotsByTag(String tag) async =>
      map[tag] ?? [];
}

TrainingPackSpot _spot(String id) => TrainingPackSpot(
  id: id,
  hand: HandData.fromSimpleInput('AhAs', HeroPosition.sb, 10),
);

void main() {
  test('generateFromWeakness collects unique spots', () async {
    final repo = _FakeRepo({
      'a': [_spot('1'), _spot('2')],
      'b': [_spot('2'), _spot('3')],
    });
    const cluster = WeaknessCluster(label: 'a', spotIds: [], avgAccuracy: 0.4);
    final mastery = {'a': 0.3, 'b': 0.4};
    final generator = TrainingPackGeneratorV2(repository: repo);
    final tpl = await generator.generateFromWeakness(
      cluster: cluster,
      mastery: mastery,
      spotCount: 3,
    );
    expect(tpl.spots.length, 3);
    expect(tpl.meta['schemaVersion'], '2.0.0');
    expect(tpl.tags.contains('a'), true);
    expect(tpl.spots.map((e) => e.id).toSet().length, 3);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/booster_variation_injector.dart';
import 'package:poker_analyzer/services/booster_cluster_engine.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

TrainingPackSpot _spot(String id, String cards, HeroPosition pos) {
  final hand = HandData.fromSimpleInput(cards, pos, 10);
  return TrainingPackSpot(id: id, hand: hand);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('injectVariations adds variations', () {
    final s1 = _spot('a', 'AhKh', HeroPosition.btn);
    final s2 = _spot('b', 'QhJh', HeroPosition.btn);
    final cluster = SpotCluster(spots: [s1, s2], clusterId: 'c1');

    final pack = TrainingPackTemplateV2(
      id: 'p1',
      name: 'Test',
      trainingType: TrainingType.pushFold,
      spots: [s1],
    );

    const injector = BoosterVariationInjector();
    final res = injector.injectVariations(pack, [cluster]);

    expect(res.spots.length, 2);
    final varSpot = res.spots.last;
    expect(varSpot.id.startsWith('a_var'), true);
    expect(varSpot.meta['variation'], true);
  });

  test('injectVariations can add multiple variations', () {
    final s1 = _spot('a', 'AhKh', HeroPosition.btn);
    final s2 = _spot('b', 'QhJh', HeroPosition.btn);
    final s3 = _spot('c', '9d8d', HeroPosition.sb);
    final cluster = SpotCluster(spots: [s1, s2, s3], clusterId: 'c1');

    final pack = TrainingPackTemplateV2(
      id: 'p1',
      name: 'Test',
      trainingType: TrainingType.pushFold,
      spots: [s1],
    );

    const injector = BoosterVariationInjector(variationsPerSpot: 2);
    final res = injector.injectVariations(pack, [cluster]);

    expect(res.spots.length, 3);
    final ids = res.spots.skip(1).map((e) => e.id).toList();
    expect(ids.where((id) => id.startsWith('a_var')).length, 2);
  });
}

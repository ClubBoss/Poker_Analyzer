import 'package:test/test.dart';
import 'package:poker_analyzer/services/yaml_pack_rating_engine.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/models/evaluation_result.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

void main() {
  TrainingPackSpot spot(int bb) {
    return TrainingPackSpot(
      id: 's$bb',
      hand: HandData(
        position: HeroPosition.sb,
        heroIndex: 0,
        stacks: {'0': bb.toDouble()},
        actions: {
          0: [ActionEntry(0, 0, 'push')],
        },
      ),
      evalResult: EvaluationResult(
        correct: true,
        expectedAction: 'push',
        userEquity: 0,
        expectedEquity: 0,
      ),
    );
  }

  test('rate returns value between 0 and 100', () {
    final tpl = TrainingPackTemplateV2(
      id: 'p1',
      name: 'Test',
      description: 'desc',
      goal: 'goal',
      meta: {'evScore': 80, 'rankScore': 0.5},
      trainingType: TrainingType.pushFold,
      spots: [spot(10), spot(15)],
    );
    final rating = const YamlPackRatingEngine().rate(tpl);
    expect(rating, inInclusiveRange(0, 100));
  });

  test('rateAll returns map by id', () {
    final a = TrainingPackTemplateV2(
      id: 'a',
      name: 'A',
      trainingType: TrainingType.pushFold,
    );
    final b = TrainingPackTemplateV2(
      id: 'b',
      name: 'B',
      trainingType: TrainingType.pushFold,
    );
    final res = const YamlPackRatingEngine().rateAll([a, b]);
    expect(res.keys, containsAll(['a', 'b']));
  });
}

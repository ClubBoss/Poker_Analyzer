import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/adaptive_learning_flow_engine.dart';
import 'package:poker_analyzer/models/training_result.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

class _Result extends TrainingResult {
  final String spotId;
  final bool isCorrect;
  final double heroEv;
  _Result({required this.spotId, required this.isCorrect, required this.heroEv})
      : super(
          date: DateTime.now(),
          total: 1,
          correct: isCorrect ? 1 : 0,
          accuracy: isCorrect ? 100 : 0,
          tags: const ['cbet'],
          evDiff: heroEv - 1,
        );
}

TrainingPackSpot _spot(String id, String tag, double ev) {
  final hand = HandData(
    position: HeroPosition.btn,
    heroIndex: 0,
    playerCount: 2,
    actions: {
      0: [ActionEntry(0, 0, 'push', ev: ev)],
    },
  );
  return TrainingPackSpot(id: id, tags: [tag], hand: hand);
}

TrainingPackTemplateV2 _pack(String id, List<TrainingPackSpot> spots) {
  return TrainingPackTemplateV2(
    id: id,
    name: id,
    trainingType: TrainingType.pushFold,
    tags: const ['cbet'],
    spots: spots,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate creates full learning plan', () {
    const engine = AdaptiveLearningFlowEngine();
    final history = [
      _Result(spotId: 's1', isCorrect: false, heroEv: 0.5),
      _Result(spotId: 's2', isCorrect: true, heroEv: 1.2),
    ];
    final mastery = {'cbet': 0.4};
    final packs = [
      _pack('p', [_spot('s1', 'cbet', -0.5), _spot('s2', 'cbet', 0.2)])
    ];

    final plan = engine.generate(
      history: history,
      tagMastery: mastery,
      sourcePacks: packs,
    );

    expect(plan.goals.isNotEmpty, true);
    expect(plan.recommendedTracks.isNotEmpty, true);
    expect(plan.mistakeReplayPack, isNotNull);
  });
}

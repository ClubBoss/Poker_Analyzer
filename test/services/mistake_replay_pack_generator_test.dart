import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/mistake_replay_pack_generator.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/models/training_result.dart';

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
        );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates pack with mistaken spots', () {
    final spot1 = TrainingPackSpot(id: 'a', hand: HandData());
    final spot2 = TrainingPackSpot(id: 'b', hand: HandData());
    final tpl = TrainingPackTemplateV2(
      id: 'p',
      name: 'test',
      trainingType: TrainingType.pushFold,
      spots: [spot1, spot2],
    );
    final results = [
      _Result(spotId: 'a', isCorrect: true, heroEv: 1.2),
      _Result(spotId: 'b', isCorrect: false, heroEv: 0.5),
    ];
    const generator = MistakeReplayPackGenerator();
    final pack = generator.generateMistakePack(
      results: results,
      sourcePacks: [tpl],
      maxSpots: 5,
    );
    expect(pack.spots.length, 1);
    expect(pack.spots.first.id, 'b');
    expect(pack.meta['origin'], 'mistake_replay');
  });
});

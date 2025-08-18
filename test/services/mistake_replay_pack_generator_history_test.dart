import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/mistake_replay_pack_generator.dart';
import 'package:poker_analyzer/models/play_result.dart';
import 'package:poker_analyzer/models/track_play_history.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate builds pack from recent mistakes', () {
    final spot1 = TrainingPackSpot(
      id: 'a',
      hand: HandData(position: HeroPosition.btn),
    );
    final spot2 = TrainingPackSpot(
      id: 'b',
      hand: HandData(position: HeroPosition.sb),
    );
    final history = [
      TrackPlayHistory(
        goalId: 'g',
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        results: [
          PlayResult(spotId: 'a', spot: spot1, isCorrect: true, evGain: 1.0),
          PlayResult(spotId: 'b', spot: spot2, isCorrect: false, evGain: 0.5),
        ],
      ),
    ];

    const generator = MistakeReplayPackGenerator();
    final pack = generator.generate(history: history, evThreshold: 0.8);

    expect(pack.spots.length, 1);
    expect(pack.spots.first.id, 'b');
    expect(pack.name, 'Ошибки последних тренировок');
  });
}

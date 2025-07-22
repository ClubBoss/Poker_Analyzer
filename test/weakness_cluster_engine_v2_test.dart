import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/weakness_cluster_engine_v2.dart';
import 'package:poker_analyzer/models/training_attempt.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('clusters low accuracy attempts', () {
    final pack = TrainingPackTemplateV2(
      id: 'p1',
      name: 'Pack 1',
      trainingType: TrainingType.pushFold,
      spots: [
        TrainingPackSpot(
          id: 's1',
          hand: HandData(position: HeroPosition.btn, board: ['Ah', 'Kd', '7c']),
          tags: ['btn vs bb'],
        ),
        TrainingPackSpot(
          id: 's2',
          hand: HandData(position: HeroPosition.btn, board: ['2h', '2d', '8c']),
          tags: ['btn vs bb'],
        ),
        TrainingPackSpot(
          id: 's3',
          hand: HandData(position: HeroPosition.btn, board: ['3h', '3d', '9c']),
          tags: ['btn vs bb'],
        ),
      ],
    );

    final attempts = [
      TrainingAttempt(
        packId: 'p1',
        spotId: 's1',
        timestamp: DateTime.now(),
        accuracy: 0.5,
        ev: 0,
        icm: 0,
      ),
      TrainingAttempt(
        packId: 'p1',
        spotId: 's2',
        timestamp: DateTime.now(),
        accuracy: 0.4,
        ev: 0,
        icm: 0,
      ),
      TrainingAttempt(
        packId: 'p1',
        spotId: 's3',
        timestamp: DateTime.now(),
        accuracy: 0.6,
        ev: 0,
        icm: 0,
      ),
    ];

    const engine = WeaknessClusterEngine();
    final clusters = engine.computeClusters(
      attempts: attempts,
      allPacks: [pack],
    );

    expect(clusters.isNotEmpty, true);
    final first = clusters.first;
    expect(first.spotIds.length, 3);
    expect(first.avgAccuracy, closeTo(0.5, 0.01));
  });
}

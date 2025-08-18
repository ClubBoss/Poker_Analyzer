import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/training_attempt.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/services/skill_targeting_recommender.dart';

void main() {
  test('recommendWeakest ranks packs by weak tag coverage', () {
    final packs = [
      TrainingPackTemplateV2(
        id: 'p1',
        name: 'Pack 1',
        trainingType: TrainingType.pushFold,
        tags: const ['a'],
        spots: [
          TrainingPackSpot(id: 's1', hand: HandData(), tags: ['a']),
        ],
      ),
      TrainingPackTemplateV2(
        id: 'p2',
        name: 'Pack 2',
        trainingType: TrainingType.pushFold,
        tags: const ['b'],
        spots: [
          TrainingPackSpot(id: 's2', hand: HandData(), tags: ['b']),
        ],
      ),
      TrainingPackTemplateV2(
        id: 'p3',
        name: 'Pack 3',
        trainingType: TrainingType.pushFold,
        tags: const ['a', 'b'],
        spots: [
          TrainingPackSpot(id: 's3', hand: HandData(), tags: ['a', 'b']),
        ],
      ),
    ];

    final attempts = [
      TrainingAttempt(
        packId: 'p1',
        spotId: 's1',
        timestamp: DateTime(2024, 1, 1),
        accuracy: 0.2,
        ev: 0,
        icm: 0,
      ),
      TrainingAttempt(
        packId: 'p2',
        spotId: 's2',
        timestamp: DateTime(2024, 1, 2),
        accuracy: 0.9,
        ev: 0,
        icm: 0,
      ),
    ];

    const recommender = SkillTargetingRecommender();
    final result = recommender.recommendWeakest(
      attempts: attempts,
      allPacks: packs,
      maxPacks: 2,
    );

    expect(result.length, 2);
    expect(result.first.id, 'p3');
    expect(result.last.id, 'p1');
  });
}

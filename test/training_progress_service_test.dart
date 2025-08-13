import 'package:test/test.dart';
import 'package:poker_analyzer/models/training_attempt.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/services/training_progress_service.dart';

void main() {
  test('computeOverallProgress calculates completion rate', () {
    final now = DateTime.now();
    final p1 = TrainingPackTemplateV2(
      id: 'p1',
      name: 'Pack 1',
      trainingType: TrainingType.pushFold,
      spots: [
        TrainingPackSpot(id: 's1', hand: HandData(), tags: ['a']),
        TrainingPackSpot(id: 's2', hand: HandData(), tags: ['a']),
      ],
    );
    final p2 = TrainingPackTemplateV2(
      id: 'p2',
      name: 'Pack 2',
      trainingType: TrainingType.pushFold,
      spots: [
        TrainingPackSpot(id: 's3', hand: HandData(), tags: ['b'])
      ],
    );
    final attempts = [
      TrainingAttempt(
        packId: 'p1',
        spotId: 's1',
        timestamp: now,
        accuracy: 1,
        ev: 0,
        icm: 0,
      ),
      TrainingAttempt(
        packId: 'p1',
        spotId: 's2',
        timestamp: now,
        accuracy: 1,
        ev: 0,
        icm: 0,
      ),
      TrainingAttempt(
        packId: 'p2',
        spotId: 's3',
        timestamp: now,
        accuracy: 0.8,
        ev: 0,
        icm: 0,
      ),
    ];

    final service = TrainingProgressService.instance;
    final progress = service.computeOverallProgress(
      attempts: attempts,
      allPacks: [p1, p2],
    );

    expect(progress.completionRate, closeTo(0.5, 0.0001));
    expect(progress.streakDays, 1);
  });

  test('computeOverallProgress detects most improved tags', () {
    final now = DateTime.now();
    final p1 = TrainingPackTemplateV2(
      id: 'p1',
      name: 'Pack 1',
      trainingType: TrainingType.pushFold,
      spots: [
        TrainingPackSpot(id: 's1', hand: HandData(), tags: ['a'])
      ],
    );
    final attempts = [
      TrainingAttempt(
        packId: 'p1',
        spotId: 's1',
        timestamp: now.subtract(const Duration(days: 8)),
        accuracy: 0.5,
        ev: 0,
        icm: 0,
      ),
      TrainingAttempt(
        packId: 'p1',
        spotId: 's1',
        timestamp: now.subtract(const Duration(days: 1)),
        accuracy: 1,
        ev: 0,
        icm: 0,
      ),
    ];

    final progress = TrainingProgressService.instance.computeOverallProgress(
      attempts: attempts,
      allPacks: [p1],
    );

    expect(progress.mostImprovedTags, contains('a'));
  });

  test('computeOverallProgress calculates streak', () {
    final now = DateTime.now();
    final p1 = TrainingPackTemplateV2(
      id: 'p1',
      name: 'Pack 1',
      trainingType: TrainingType.pushFold,
      spots: [
        TrainingPackSpot(id: 's1', hand: HandData(), tags: ['a'])
      ],
    );
    final attempts = [
      for (int i = 0; i < 3; i++)
        TrainingAttempt(
          packId: 'p1',
          spotId: 's1',
          timestamp: now.subtract(Duration(days: i)),
          accuracy: 1,
          ev: 0,
          icm: 0,
        ),
    ];

    final progress = TrainingProgressService.instance.computeOverallProgress(
      attempts: attempts,
      allPacks: [p1],
    );

    expect(progress.streakDays, greaterThanOrEqualTo(3));
  });
}

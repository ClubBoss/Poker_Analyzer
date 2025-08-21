import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/adaptive_training_path_engine.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/models/learning_path_template_v2.dart';
import 'package:poker_analyzer/models/training_attempt.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/services/training_pack_stats_service.dart';

TrainingPackTemplateV2 _pack(String id, String tag) {
  return TrainingPackTemplateV2(
    id: id,
    name: id,
    trainingType: TrainingType.pushFold,
    tags: [tag],
    positions: [HeroPosition.sb.name],
    spots: [
      TrainingPackSpot(
        id: 's1',
        hand: HandData(position: HeroPosition.sb, board: ['Ah', 'Kd', '2c']),
        tags: [tag],
      ),
      TrainingPackSpot(
        id: 's2',
        hand: HandData(position: HeroPosition.sb, board: ['2h', '3d', '4c']),
        tags: [tag],
      ),
      TrainingPackSpot(
        id: 's3',
        hand: HandData(position: HeroPosition.sb, board: ['5h', '6d', '7c']),
        tags: [tag],
      ),
    ],
  );
}

TrainingAttempt _attempt(String packId, String spotId, double acc) =>
    TrainingAttempt(
      packId: packId,
      spotId: spotId,
      timestamp: DateTime.now(),
      accuracy: acc,
      ev: 0,
      icm: 0,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const engine = AdaptiveTrainingPathEngine();

  LearningPathTemplateV2 path() => const LearningPathTemplateV2(
        id: 'p',
        title: 'Path',
        description: '',
        stages: [
          LearningPathStageModel(
            id: 's1',
            title: 'S1',
            description: '',
            packId: 'p1',
            requiredAccuracy: 90,
            minHands: 0,
            unlocks: ['s2'],
            tags: ['a'],
          ),
          LearningPathStageModel(
            id: 's2',
            title: 'S2',
            description: '',
            packId: 'p2',
            requiredAccuracy: 90,
            minHands: 0,
            tags: ['b'],
          ),
        ],
      );

  test('unlocks next stage when weakness detected and prereqs met', () {
    final packs = [_pack('p1', 'a'), _pack('p2', 'b')];
    final stats = {'p1': TrainingPackStat(accuracy: 95, last: DateTime.now())};
    final attempts = [
      _attempt('p2', 's1', 0.5),
      _attempt('p2', 's2', 0.4),
      _attempt('p2', 's3', 0.6),
    ];
    final ids = engine.getUnlockedStageIds(
      allPacks: packs,
      stats: stats,
      attempts: attempts,
      path: path(),
    );
    expect(ids.contains('s1'), isTrue);
    expect(ids.contains('s2'), isTrue);
  });

  test('stage locked when prereqs not complete', () {
    final packs = [_pack('p1', 'a'), _pack('p2', 'b')];
    final stats = <String, TrainingPackStat>{};
    final attempts = [
      _attempt('p2', 's1', 0.5),
      _attempt('p2', 's2', 0.4),
      _attempt('p2', 's3', 0.6),
    ];
    final ids = engine.getUnlockedStageIds(
      allPacks: packs,
      stats: stats,
      attempts: attempts,
      path: path(),
    );
    expect(ids.contains('s1'), isTrue);
    expect(ids.contains('s2'), isFalse);
  });

  test('stage locked when no weakness', () {
    final packs = [_pack('p1', 'a'), _pack('p2', 'b')];
    final stats = {'p1': TrainingPackStat(accuracy: 95, last: DateTime.now())};
    final attempts = <TrainingAttempt>[];
    final ids = engine.getUnlockedStageIds(
      allPacks: packs,
      stats: stats,
      attempts: attempts,
      path: path(),
    );
    expect(ids.contains('s1'), isTrue);
    expect(ids.contains('s2'), isFalse);
  });
}

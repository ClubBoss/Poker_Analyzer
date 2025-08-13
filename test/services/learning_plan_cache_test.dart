import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/adaptive_learning_flow_engine.dart';
import 'package:poker_analyzer/services/learning_plan_cache.dart';
import 'package:poker_analyzer/models/learning_goal.dart';
import 'package:poker_analyzer/models/training_track.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('save and load roundtrip', () async {
    const cache = LearningPlanCache();

    final spot = TrainingPackSpot(
      id: 's1',
      title: 'Spot',
      hand: HandData(
        position: HeroPosition.btn,
        heroIndex: 0,
        playerCount: 2,
        actions: {
          0: [ActionEntry(0, 0, 'push', ev: 1.0)],
        },
      ),
    );
    final track = TrainingTrack(
      id: 't1',
      title: 'Track',
      goalId: 'g1',
      spots: [spot],
      tags: const ['push'],
    );
    const goal = LearningGoal(
      id: 'g1',
      title: 'Goal',
      description: 'desc',
      tag: 'push',
      priorityScore: 1.0,
    );
    final replay = TrainingPackTemplateV2(
      id: 'p1',
      name: 'Replay',
      trainingType: TrainingType.pushFold,
      tags: const [],
      spots: const [],
      spotCount: 0,
      created: DateTime.now(),
      gameType: GameType.tournament,
      positions: const [],
    );
    final plan = AdaptiveLearningPlan(
      recommendedTracks: [track],
      goals: [goal],
      mistakeReplayPack: replay,
    );

    await cache.save(plan);

    final loaded = await cache.load();
    expect(loaded, isNotNull);
    expect(loaded!.goals.first.id, 'g1');
    expect(loaded.recommendedTracks.first.id, 't1');
    expect(loaded.mistakeReplayPack?.id, 'p1');
  });

  test('invalid data returns null', () async {
    SharedPreferences.setMockInitialValues({'learning_plan_cache': 'oops'});
    const cache = LearningPlanCache();
    final result = await cache.load();
    expect(result, isNull);
  });
}

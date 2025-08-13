import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/training_session_recommender.dart';
import 'package:poker_analyzer/services/adaptive_learning_flow_engine.dart';
import 'package:poker_analyzer/models/training_track.dart';
import 'package:poker_analyzer/models/track_play_history.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TrainingPackTemplateV2 pack(String id) {
    return TrainingPackTemplateV2(
      id: id,
      name: id,
      trainingType: TrainingType.pushFold,
      spots: const [],
    );
  }

  TrainingTrack track(String id, String goal) {
    return TrainingTrack(
        id: id, title: id, goalId: goal, spots: const [], tags: const []);
  }

  test('prioritizes mistake replay over tracks', () {
    final plan = AdaptiveLearningPlan(
      recommendedTracks: [track('t1', 'g1'), track('t2', 'g2')],
      goals: const [],
      mistakeReplayPack: pack('m1'),
    );

    final history = [
      TrackPlayHistory(
        goalId: 'g1',
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
      ),
    ];

    final recs = const TrainingSessionRecommender().recommend(
      plan: plan,
      history: history,
    );

    expect(recs.first.packId, 'm1');
    expect(recs.length, 3);
    expect(recs[1].packId, 't2');
    expect(recs[2].packId, 't1');
  });
}

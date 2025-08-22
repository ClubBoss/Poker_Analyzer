import '../models/training_recommendation.dart';
import '../models/track_play_history.dart';
import 'adaptive_learning_flow_engine.dart';
import '../models/training_track.dart';

/// Suggests which training session to play next based on the current
/// [AdaptiveLearningPlan] and past [TrackPlayHistory].
class TrainingSessionRecommender {
  TrainingSessionRecommender();

  List<TrainingRecommendation> recommend({
    required AdaptiveLearningPlan plan,
    required List<TrackPlayHistory> history,
  }) {
    double progressFor(String goalId) {
      final count = history
          .where((h) => h.goalId == goalId && h.completedAt != null)
          .length;
      return (count / 3).clamp(0.0, 1.0);
    }

    final recs = <TrainingRecommendation>[];

    final mistakePack = plan.mistakeReplayPack;
    if (mistakePack != null) {
      recs.add(
        TrainingRecommendation(
          title: mistakePack.name,
          type: TrainingRecommendationType.mistakeReplay,
          score: 1000,
          packId: mistakePack.id,
          reason: 'mistake_replay',
          progress: progressFor('mistake_replay'),
          isUrgent: true,
        ),
      );
    }

    final trackEntries = <MapEntry<TrainingTrack, double>>[];
    for (final t in plan.recommendedTracks) {
      final p = progressFor(t.goalId);
      if (p < 1.0) {
        trackEntries.add(MapEntry(t, p));
      }
    }
    trackEntries.sort((a, b) => a.value.compareTo(b.value));
    for (final entry in trackEntries) {
      final t = entry.key;
      final p = entry.value;
      recs.add(
        TrainingRecommendation(
          title: t.title,
          type: TrainingRecommendationType.weaknessDrill,
          goalTag: t.goalId,
          score: 500 * (1 - p),
          packId: t.id,
          reason: 'goal_track',
          progress: p,
          isUrgent: p < 0.3,
        ),
      );
    }

    return recs;
  }
}

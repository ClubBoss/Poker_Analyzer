import '../models/learning_goal.dart';
import '../models/training_result.dart';
import '../models/training_track.dart';
import '../models/training_recommendation.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/weakness_cluster_engine.dart';
import '../services/learning_goal_engine.dart';
import '../services/dynamic_track_builder.dart';
import '../services/adaptive_scheduler_service.dart';
import '../services/mistake_replay_pack_generator.dart';

class AdaptiveLearningPlan {
  final List<TrainingTrack> recommendedTracks;
  final List<LearningGoal> goals;
  final TrainingPackTemplateV2? mistakeReplayPack;

  AdaptiveLearningPlan({
    required this.recommendedTracks,
    required this.goals,
    this.mistakeReplayPack,
  });
}

class AdaptiveLearningFlowEngine {
  final WeaknessClusterEngine clusterEngine;
  final LearningGoalEngine goalEngine;
  final DynamicTrackBuilder trackBuilder;
  final AdaptiveSchedulerService scheduler;
  final MistakeReplayPackGenerator mistakeGenerator;

  AdaptiveLearningFlowEngine({
    this.clusterEngine = const WeaknessClusterEngine(),
    this.goalEngine = const LearningGoalEngine(),
    this.trackBuilder = const DynamicTrackBuilder(),
    this.scheduler = const AdaptiveSchedulerService(),
    this.mistakeGenerator = const MistakeReplayPackGenerator(),
  });

  AdaptiveLearningPlan generate({
    required List<TrainingResult> history,
    required Map<String, double> tagMastery,
    required List<TrainingPackTemplateV2> sourcePacks,
  }) {
    final clusters = clusterEngine.detectWeaknesses(
      results: history,
      tagMastery: tagMastery,
    );
    final goals = goalEngine.generateGoals(clusters);
    final tracks = trackBuilder.buildTracks(
      goals: goals,
      sourcePacks: sourcePacks,
    );
    final recs = scheduler.getNextRecommendations(
      clusters: clusters,
      history: history,
      tagMastery: tagMastery,
    );

    TrainingPackTemplateV2? replayPack;
    final needReplay = recs.any(
      (r) => r.type == TrainingRecommendationType.mistakeReplay,
    );
    if (needReplay && history.isNotEmpty) {
      replayPack = mistakeGenerator.generateMistakePack(
        results: history,
        sourcePacks: sourcePacks,
      );
    }

    return AdaptiveLearningPlan(
      recommendedTracks: tracks,
      goals: goals,
      mistakeReplayPack: replayPack,
    );
  }
}

import 'package:json_annotation/json_annotation.dart';

import '../models/learning_goal.dart';
import '../models/training_track.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'adaptive_learning_flow_engine.dart';

part 'learning_plan_cache_models.g.dart';

/// Cached representation of [AdaptiveLearningPlan].
@JsonSerializable(explicitToJson: true)
class CachedLearningPlan {
  final List<CachedLearningGoal> goals;
  final List<CachedTrainingTrack> tracks;
  final TrainingPackTemplateV2? mistakePack;

  const CachedLearningPlan({
    required this.goals,
    required this.tracks,
    this.mistakePack,
  });

  factory CachedLearningPlan.fromPlan(AdaptiveLearningPlan plan) =>
      CachedLearningPlan(
        goals: [for (final g in plan.goals) CachedLearningGoal.fromGoal(g)],
        tracks: [
          for (final t in plan.recommendedTracks)
            CachedTrainingTrack.fromTrack(t),
        ],
        mistakePack: plan.mistakeReplayPack,
      );

  AdaptiveLearningPlan toPlan() => AdaptiveLearningPlan(
    recommendedTracks: [for (final t in tracks) t.toTrack()],
    goals: [for (final g in goals) g.toGoal()],
    mistakeReplayPack: mistakePack,
  );

  factory CachedLearningPlan.fromJson(Map<String, dynamic> json) =>
      _$CachedLearningPlanFromJson(json);
  Map<String, dynamic> toJson() => _$CachedLearningPlanToJson(this);
}

/// Cached representation of [LearningGoal].
@JsonSerializable()
class CachedLearningGoal {
  final String id;
  final String title;
  final String description;
  final String tag;
  final double priority;

  const CachedLearningGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.tag,
    required this.priority,
  });

  factory CachedLearningGoal.fromGoal(LearningGoal goal) => CachedLearningGoal(
    id: goal.id,
    title: goal.title,
    description: goal.description,
    tag: goal.tag,
    priority: goal.priorityScore,
  );

  LearningGoal toGoal() => LearningGoal(
    id: id,
    title: title,
    description: description,
    tag: tag,
    priorityScore: priority,
  );

  factory CachedLearningGoal.fromJson(Map<String, dynamic> json) =>
      _$CachedLearningGoalFromJson(json);
  Map<String, dynamic> toJson() => _$CachedLearningGoalToJson(this);
}

/// Cached representation of [TrainingTrack].
@JsonSerializable(explicitToJson: true)
class CachedTrainingTrack {
  final String id;
  final String title;
  final String goalId;
  final List<TrainingPackSpot> spots;
  final List<String> tags;

  const CachedTrainingTrack({
    required this.id,
    required this.title,
    required this.goalId,
    required this.spots,
    required this.tags,
  });

  factory CachedTrainingTrack.fromTrack(TrainingTrack track) =>
      CachedTrainingTrack(
        id: track.id,
        title: track.title,
        goalId: track.goalId,
        spots: track.spots,
        tags: track.tags,
      );

  TrainingTrack toTrack() => TrainingTrack(
    id: id,
    title: title,
    goalId: goalId,
    spots: spots,
    tags: tags,
  );

  factory CachedTrainingTrack.fromJson(Map<String, dynamic> json) =>
      _$CachedTrainingTrackFromJson(json);
  Map<String, dynamic> toJson() => _$CachedTrainingTrackToJson(this);
}

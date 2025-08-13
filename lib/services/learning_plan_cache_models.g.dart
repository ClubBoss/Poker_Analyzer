// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_plan_cache_models.dart';

CachedLearningPlan _$CachedLearningPlanFromJson(Map<String, dynamic> json) =>
    CachedLearningPlan(
      goals: (json['goals'] as List<dynamic>)
          .map((e) => CachedLearningGoal.fromJson(e as Map<String, dynamic>))
          .toList(),
      tracks: (json['tracks'] as List<dynamic>)
          .map((e) => CachedTrainingTrack.fromJson(e as Map<String, dynamic>))
          .toList(),
      mistakePack: json['mistakePack'] == null
          ? null
          : TrainingPackTemplateV2.fromJson(
              json['mistakePack'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$CachedLearningPlanToJson(CachedLearningPlan instance) =>
    <String, dynamic>{
      'goals': instance.goals.map((e) => e.toJson()).toList(),
      'tracks': instance.tracks.map((e) => e.toJson()).toList(),
      'mistakePack': instance.mistakePack?.toJson(),
    };

CachedLearningGoal _$CachedLearningGoalFromJson(Map<String, dynamic> json) =>
    CachedLearningGoal(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      tag: json['tag'] as String,
      priority: (json['priority'] as num).toDouble(),
    );

Map<String, dynamic> _$CachedLearningGoalToJson(CachedLearningGoal instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'tag': instance.tag,
      'priority': instance.priority,
    };

CachedTrainingTrack _$CachedTrainingTrackFromJson(Map<String, dynamic> json) =>
    CachedTrainingTrack(
      id: json['id'] as String,
      title: json['title'] as String,
      goalId: json['goalId'] as String,
      spots: (json['spots'] as List<dynamic>)
          .map((e) => TrainingPackSpot.fromJson(e as Map<String, dynamic>))
          .toList(),
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$CachedTrainingTrackToJson(
  CachedTrainingTrack instance,
) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'goalId': instance.goalId,
      'spots': instance.spots.map((e) => e.toJson()).toList(),
      'tags': instance.tags,
    };

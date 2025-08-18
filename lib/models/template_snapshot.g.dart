// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TemplateSnapshot _$TemplateSnapshotFromJson(Map<String, dynamic> json) =>
    TemplateSnapshot(
      id: json['id'] as String?,
      comment: json['comment'] as String,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      spots: (json['spots'] as List<dynamic>)
          .map((e) => TrainingPackSpot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TemplateSnapshotToJson(TemplateSnapshot instance) =>
    <String, dynamic>{
      'id': instance.id,
      'comment': instance.comment,
      'timestamp': instance.timestamp.toIso8601String(),
      'spots': instance.spots.map((e) => e.toJson()).toList(),
    };

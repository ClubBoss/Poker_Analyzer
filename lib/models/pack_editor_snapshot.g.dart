// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_editor_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackEditorSnapshot _$PackEditorSnapshotFromJson(Map<String, dynamic> json) =>
    PackEditorSnapshot(
      id: json['id'] as String?,
      name: json['name'] as String,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      hands: (json['hands'] as List<dynamic>)
          .map((e) => SavedHand.fromJson(e as Map<String, dynamic>))
          .toList(),
      views: (json['views'] as List<dynamic>)
          .map((e) => ViewPreset.fromJson(e as Map<String, dynamic>))
          .toList(),
      filters: json['filters'] as Map<String, dynamic>,
      isAuto: json['isAuto'] as bool? ?? false,
    );

Map<String, dynamic> _$PackEditorSnapshotToJson(PackEditorSnapshot instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'timestamp': instance.timestamp.toIso8601String(),
      'hands': instance.hands.map((e) => e.toJson()).toList(),
      'views': instance.views.map((e) => e.toJson()).toList(),
      'filters': instance.filters,
      'isAuto': instance.isAuto,
    };

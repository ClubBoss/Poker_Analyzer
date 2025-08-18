// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackSnapshot _$PackSnapshotFromJson(Map<String, dynamic> json) => PackSnapshot(
      id: json['id'] as String?,
      comment: json['comment'] as String? ?? '',
      date:
          json['date'] == null ? null : DateTime.parse(json['date'] as String),
      hands: (json['hands'] as List<dynamic>)
          .map((e) => SavedHand.fromJson(e as Map<String, dynamic>))
          .toList(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      orderHash: (json['orderHash'] as num).toInt(),
    );

Map<String, dynamic> _$PackSnapshotToJson(PackSnapshot instance) =>
    <String, dynamic>{
      'id': instance.id,
      'comment': instance.comment,
      'date': instance.date.toIso8601String(),
      'hands': instance.hands.map((e) => e.toJson()).toList(),
      'tags': instance.tags,
      'orderHash': instance.orderHash,
    };

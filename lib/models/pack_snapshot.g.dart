part of 'pack_snapshot.dart';

PackSnapshot _$PackSnapshotFromJson(Map<String, dynamic> json) => PackSnapshot(
  id: json['id'] as String?,
  comment: json['comment'] as String? ?? '',
  date: DateTime.parse(json['date'] as String),
  hands: const [],
  tags: const [],
  orderHash: json['orderHash'] as int? ?? 0,
);

Map<String, dynamic> _$PackSnapshotToJson(PackSnapshot instance) =>
    <String, dynamic>{};

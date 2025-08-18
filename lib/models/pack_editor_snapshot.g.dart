part of 'pack_editor_snapshot.dart';

PackEditorSnapshot _$PackEditorSnapshotFromJson(Map<String, dynamic> json) =>
    PackEditorSnapshot(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      hands: const [],
      views: const [],
      filters: json['filters'] as Map<String, dynamic>? ?? const {},
      isAuto: json['isAuto'] as bool? ?? false,
    );

Map<String, dynamic> _$PackEditorSnapshotToJson(PackEditorSnapshot instance) =>
    <String, dynamic>{};

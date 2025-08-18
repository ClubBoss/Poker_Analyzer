part of 'template_snapshot.dart';

TemplateSnapshot _$TemplateSnapshotFromJson(Map<String, dynamic> json) =>
    TemplateSnapshot(
      id: json['id'] as String?,
      comment: json['comment'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      spots: const [],
    );

Map<String, dynamic> _$TemplateSnapshotToJson(TemplateSnapshot instance) =>
    <String, dynamic>{};

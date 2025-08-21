import 'package:uuid/uuid.dart';
import 'v2/training_pack_spot.dart';
import 'package:json_annotation/json_annotation.dart';

part 'template_snapshot.g.dart';

@JsonSerializable(explicitToJson: true)
class TemplateSnapshot {
  final String id;
  final String comment;
  final DateTime timestamp;
  final List<TrainingPackSpot> spots;

  TemplateSnapshot({
    String? id,
    required this.comment,
    DateTime? timestamp,
    required this.spots,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  factory TemplateSnapshot.fromJson(Map<String, dynamic> json) =>
      _$TemplateSnapshotFromJson(json);
  Map<String, dynamic> toJson() => _$TemplateSnapshotToJson(this);
}

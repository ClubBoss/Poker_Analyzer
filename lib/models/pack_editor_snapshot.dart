import 'package:uuid/uuid.dart';
import 'saved_hand.dart';
import 'view_preset.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_editor_snapshot.g.dart';

@JsonSerializable(explicitToJson: true)
class PackEditorSnapshot {
  final String id;
  final String name;
  final DateTime timestamp;
  final List<SavedHand> hands;
  final List<ViewPreset> views;
  final Map<String, dynamic> filters;
  final bool isAuto;

  PackEditorSnapshot({
    String? id,
    required this.name,
    DateTime? timestamp,
    required this.hands,
    required this.views,
    required this.filters,
    this.isAuto = false,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  factory PackEditorSnapshot.fromJson(Map<String, dynamic> json) =>
      _$PackEditorSnapshotFromJson(json);
  Map<String, dynamic> toJson() => _$PackEditorSnapshotToJson(this);

  PackEditorSnapshot copyWith({String? name}) => PackEditorSnapshot(
        id: id,
        name: name ?? this.name,
        timestamp: timestamp,
        hands: hands,
        views: views,
        filters: filters,
        isAuto: isAuto,
      );
}

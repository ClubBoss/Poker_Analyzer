import 'package:uuid/uuid.dart';
import 'saved_hand.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_snapshot.g.dart';

@JsonSerializable(explicitToJson: true)
class PackSnapshot {
  final String id;
  final String comment;
  final DateTime date;
  final List<SavedHand> hands;
  final List<String> tags;
  final int orderHash;

  PackSnapshot({
    String? id,
    this.comment = '',
    DateTime? date,
    required this.hands,
    List<String>? tags,
    required this.orderHash,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now(),
        tags = tags ?? const [];

  factory PackSnapshot.fromJson(Map<String, dynamic> json) =>
      _$PackSnapshotFromJson(json);
  Map<String, dynamic> toJson() => _$PackSnapshotToJson(this);
}

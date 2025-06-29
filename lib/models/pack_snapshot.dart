import 'package:uuid/uuid.dart';
import 'saved_hand.dart';

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'comment': comment,
        'date': date.toIso8601String(),
        'hands': [for (final h in hands) h.toJson()],
        'tags': tags,
        'orderHash': orderHash,
      };

  factory PackSnapshot.fromJson(Map<String, dynamic> json) => PackSnapshot(
        id: json['id'] as String?,
        comment: json['comment'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        hands: [
          for (final h in (json['hands'] as List? ?? []))
            SavedHand.fromJson(Map<String, dynamic>.from(h as Map))
        ],
        tags: [for (final t in (json['tags'] as List? ?? [])) t as String],
        orderHash: (json['orderHash'] as num?)?.toInt() ?? 0,
      );
}

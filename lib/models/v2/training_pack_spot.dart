import 'package:collection/collection.dart';
import 'hand_data.dart';
import '../evaluation_result.dart';

class TrainingPackSpot {
  final String id;
  String title;
  String note;
  HandData hand;
  List<String> tags;
  DateTime editedAt;
  bool pinned;
  EvaluationResult? evalResult;

  TrainingPackSpot({
    required this.id,
    this.title = '',
    this.note = '',
    HandData? hand,
    List<String>? tags,
    DateTime? editedAt,
    this.pinned = false,
    this.evalResult,
  })  : hand = hand ?? HandData(),
        tags = tags ?? [],
        editedAt = editedAt ?? DateTime.now();

  TrainingPackSpot copyWith({
    String? id,
    String? title,
    String? note,
    HandData? hand,
    List<String>? tags,
    DateTime? editedAt,
    bool? pinned,
    EvaluationResult? evalResult,
  }) =>
      TrainingPackSpot(
        id: id ?? this.id,
        title: title ?? this.title,
        note: note ?? this.note,
        hand: hand ?? this.hand,
        tags: tags ?? List<String>.from(this.tags),
        editedAt: editedAt ?? this.editedAt,
        pinned: pinned ?? this.pinned,
        evalResult: evalResult ?? this.evalResult,
      );

  factory TrainingPackSpot.fromJson(Map<String, dynamic> j) => TrainingPackSpot(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        note: j['note'] as String? ?? '',
        hand: j['hand'] != null
            ? HandData.fromJson(Map<String, dynamic>.from(j['hand']))
            : HandData(),
        tags: [for (final t in (j['tags'] as List? ?? [])) t as String],
        editedAt:
            DateTime.tryParse(j['editedAt'] as String? ?? '') ?? DateTime.now(),
        pinned: j['pinned'] == true,
        evalResult: j['evalResult'] != null
            ? EvaluationResult.fromJson(
                Map<String, dynamic>.from(j['evalResult']))
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'hand': hand.toJson(),
        if (tags.isNotEmpty) 'tags': tags,
        'editedAt': editedAt.toIso8601String(),
        if (pinned) 'pinned': true,
        if (evalResult != null) 'evalResult': evalResult!.toJson(),
      };

  double? get heroEv {
    final acts = hand.actions[0] ?? [];
    for (final a in acts) {
      if (a.playerIndex == hand.heroIndex && a.ev != null) return a.ev;
    }
    return null;
  }

  double? get heroIcmEv {
    final acts = hand.actions[0] ?? [];
    for (final a in acts) {
      if (a.playerIndex == hand.heroIndex && a.icmEv != null) return a.icmEv;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingPackSpot &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          note == other.note &&
          hand == other.hand &&
          const ListEquality().equals(tags, other.tags) &&
          pinned == other.pinned &&
          evalResult == other.evalResult;

  @override
  int get hashCode =>
      Object.hash(id, title, note, hand, const ListEquality().hash(tags), pinned,
          evalResult);
}

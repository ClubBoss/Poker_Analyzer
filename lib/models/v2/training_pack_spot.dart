import 'package:collection/collection.dart';
import 'hand_data.dart';
import '../evaluation_result.dart';

class TrainingPackSpot {
  final String id;
  String title;
  String note;
  HandData hand;
  List<String> tags;
  List<String> categories;
  DateTime editedAt;
  DateTime createdAt;
  bool pinned;
  bool dirty;

  /// Ephemeral flag — used only in RAM to highlight freshly imported spots.
  /// Never written to / read from JSON.
  bool isNew = false;
  EvaluationResult? evalResult;
  String? correctAction;
  String? explanation;

  TrainingPackSpot({
    required this.id,
    this.title = '',
    this.note = '',
    HandData? hand,
    List<String>? tags,
    List<String>? categories,
    DateTime? editedAt,
    DateTime? createdAt,
    this.pinned = false,
    this.dirty = false,
    bool? isNew,
    this.evalResult,
    this.correctAction,
    this.explanation,
  }) : isNew = isNew ?? false,
       hand = hand ?? HandData(),
       tags = tags ?? [],
       categories = categories ?? [],
       editedAt = editedAt ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  TrainingPackSpot copyWith({
    String? id,
    String? title,
    String? note,
    HandData? hand,
    List<String>? tags,
    List<String>? categories,
    DateTime? editedAt,
    DateTime? createdAt,
    bool? pinned,
    bool? dirty,
    bool? isNew,
    EvaluationResult? evalResult,
    String? correctAction,
    String? explanation,
  }) => TrainingPackSpot(
    id: id ?? this.id,
    title: title ?? this.title,
    note: note ?? this.note,
    hand: hand ?? this.hand,
    tags: tags ?? List<String>.from(this.tags),
    categories: categories ?? List<String>.from(this.categories),
    editedAt: editedAt ?? this.editedAt,
    createdAt: createdAt ?? this.createdAt,
    pinned: pinned ?? this.pinned,
    dirty: dirty ?? this.dirty,
    isNew: isNew ?? this.isNew,
    evalResult: evalResult ?? this.evalResult,
    correctAction: correctAction ?? this.correctAction,
    explanation: explanation ?? this.explanation,
  );

  factory TrainingPackSpot.fromJson(Map<String, dynamic> j) => TrainingPackSpot(
    id: j['id'] as String? ?? '',
    title: j['title'] as String? ?? '',
    note: j['note'] as String? ?? '',
    hand: j['hand'] != null
        ? HandData.fromJson(Map<String, dynamic>.from(j['hand']))
        : HandData(),
    tags: [for (final t in (j['tags'] as List? ?? [])) t as String],
    categories: [for (final t in (j['categories'] as List? ?? [])) t as String],
    editedAt:
        DateTime.tryParse(j['editedAt'] as String? ?? '') ?? DateTime.now(),
    createdAt:
        DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
    pinned: j['pinned'] == true,
    dirty: j['dirty'] == true,
    // `isNew` never restored from disk
    isNew: false,
    evalResult: j['evalResult'] != null
        ? EvaluationResult.fromJson(Map<String, dynamic>.from(j['evalResult']))
        : null,
    correctAction: j['correctAction'] as String?,
    explanation: j['explanation'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'note': note,
    'hand': hand.toJson(),
    if (tags.isNotEmpty) 'tags': tags,
    if (categories.isNotEmpty) 'categories': categories,
    'editedAt': editedAt.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    if (pinned) 'pinned': true,
    if (dirty) 'dirty': true,
    if (evalResult != null) 'evalResult': evalResult!.toJson(),
    if (correctAction != null) 'correctAction': correctAction,
    if (explanation != null) 'explanation': explanation,
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
          const ListEquality().equals(categories, other.categories) &&
          pinned == other.pinned &&
          dirty == other.dirty &&
          isNew == other.isNew &&
          evalResult == other.evalResult &&
          correctAction == other.correctAction &&
          explanation == other.explanation;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    note,
    hand,
    const ListEquality().hash(tags),
    const ListEquality().hash(categories),
    pinned,
    dirty,
    isNew,
    evalResult,
    correctAction,
    explanation,
  );
}

extension TrainingPackSpotStreet on TrainingPackSpot {
  int get street {
    final n = hand.board.length;
    if (n >= 5) return 3;
    if (n == 4) return 2;
    if (n >= 3) return 1;
    return 0;
  }
}

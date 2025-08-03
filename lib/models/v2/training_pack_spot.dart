import 'hand_data.dart';
import '../evaluation_result.dart';
import '../copy_with_mixin.dart';
import '../action_entry.dart';
import '../training_spot.dart';
import 'hero_position.dart';
import '../card_model.dart';
import 'package:uuid/uuid.dart';
import '../../services/inline_theory_linker.dart';

class TrainingPackSpot with CopyWithMixin<TrainingPackSpot> {
  final String id;
  String type;
  String title;
  String note;
  HandData hand;
  List<String> tags;
  List<String> categories;
  DateTime editedAt;
  DateTime createdAt;
  bool pinned;
  bool dirty;
  int priority;

  /// Ephemeral flag — used only in RAM to highlight freshly imported spots.
  /// Never written to / read from JSON.
  bool isNew = false;

  /// Ephemeral flag – marks automatically generated variations.
  /// Never written to / read from JSON.
  bool isGenerated = false;
  EvaluationResult? evalResult;
  String? correctAction;
  String? explanation;
  String? image;
  bool streetMode;
  List<String> board;
  int street;
  String? villainAction;
  List<String> heroOptions;
  Map<String, dynamic> meta;

  /// Optional reference to the template spot that produced this variation.
  String? templateSourceId;

  /// Ephemeral link to a related theory lesson.
  ///
  /// This field is populated at runtime by [AutoSpotTheoryInjectorService]
  /// and is never serialized.
  InlineTheoryLink? theoryLink;

  TrainingPackSpot({
    required this.id,
    this.type = 'quiz',
    this.title = '',
    this.note = '',
    HandData? hand,
    List<String>? tags,
    List<String>? categories,
    DateTime? editedAt,
    DateTime? createdAt,
    this.pinned = false,
    this.dirty = false,
    this.priority = 3,
    bool? isNew,
    bool? isGenerated,
    this.evalResult,
    this.correctAction,
    this.explanation,
    this.image,
    this.streetMode = false,
    List<String>? board,
    this.street = 0,
    this.villainAction,
    List<String>? heroOptions,
    Map<String, dynamic>? meta,
    this.templateSourceId,
  })  : isNew = isNew ?? false,
        isGenerated = isGenerated ?? false,
        hand = hand ?? HandData(),
        board = board ?? const [],
        heroOptions = heroOptions ?? const [],
        meta = meta ?? {},
        tags = tags ?? [],
        categories = categories ?? [],
        editedAt = editedAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  factory TrainingPackSpot.fromJson(Map<String, dynamic> j) => TrainingPackSpot(
        id: j['id'] as String? ?? '',
        type: j['type'] as String? ?? 'quiz',
        title: j['title'] as String? ?? '',
        note: j['note'] as String? ?? '',
        hand: j['hand'] != null
            ? HandData.fromJson(Map<String, dynamic>.from(j['hand']))
            : HandData(),
        tags: [for (final t in (j['tags'] as List? ?? [])) t as String],
        categories: [
          for (final t in (j['categories'] as List? ?? [])) t as String
        ],
        editedAt:
            DateTime.tryParse(j['editedAt'] as String? ?? '') ?? DateTime.now(),
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
        pinned: j['pinned'] == true,
        dirty: j['dirty'] == true,
        priority: (j['priority'] as num?)?.toInt() ?? 3,
        // `isNew` never restored from disk
        isNew: false,
        evalResult: j['evalResult'] != null
            ? EvaluationResult.fromJson(
                Map<String, dynamic>.from(j['evalResult']))
            : null,
        correctAction: j['correctAction'] as String?,
        explanation: j['explanation'] as String?,
        image: j['image'] as String?,
        streetMode: j['streetMode'] == true,
        board: [for (final c in (j['board'] as List? ?? [])) c.toString()],
        street: (j['street'] as num?)?.toInt() ?? 0,
        villainAction: j['villainAction'] as String?,
        heroOptions: [
          for (final a in (j['heroOptions'] as List? ?? [])) a.toString()
        ],
        meta: j['meta'] != null ? Map<String, dynamic>.from(j['meta']) : {},
        templateSourceId: j['templateSourceId'] as String?,
      );

  factory TrainingPackSpot.fromTrainingSpot(
    TrainingSpot spot, {
    String? id,
    String? villainAction,
    List<String>? heroOptions,
  }) {
    final heroCards = spot.playerCards.length > spot.heroIndex
        ? spot.playerCards[spot.heroIndex]
        : <CardModel>[];
    final cardStr = heroCards.map((c) => '${c.rank}${c.suit}').join(' ');
    final actions = <int, List<ActionEntry>>{};
    for (final a in spot.actions) {
      actions.putIfAbsent(a.street, () => []).add(
            ActionEntry(a.street, a.playerIndex, a.action, amount: a.amount),
          );
    }
    final stacks = <String, double>{};
    for (var i = 0; i < spot.stacks.length; i++) {
      stacks['$i'] = spot.stacks[i].toDouble();
    }
    final boardList = [for (final c in spot.boardCards) '${c.rank}${c.suit}'];
    final handData = HandData(
      heroCards: cardStr,
      position: parseHeroPosition(spot.heroPosition ?? ''),
      heroIndex: spot.heroIndex,
      playerCount: spot.numberOfPlayers,
      actions: actions,
      stacks: stacks,
      board: boardList,
    );
    return TrainingPackSpot(
      id: id ?? const Uuid().v4(),
      hand: handData,
      board: boardList,
      villainAction: villainAction,
      heroOptions: heroOptions ?? const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'note': note,
        'hand': hand.toJson(),
        if (tags.isNotEmpty) 'tags': tags,
        if (categories.isNotEmpty) 'categories': categories,
        'editedAt': editedAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        if (pinned) 'pinned': true,
        if (dirty) 'dirty': true,
        if (priority != 3) 'priority': priority,
        if (evalResult != null) 'evalResult': evalResult!.toJson(),
        if (correctAction != null) 'correctAction': correctAction,
        if (explanation != null) 'explanation': explanation,
        if (image != null) 'image': image,
        if (streetMode) 'streetMode': true,
        if (board.isNotEmpty) 'board': board,
        if (street > 0) 'street': street,
        if (villainAction != null) 'villainAction': villainAction,
        if (heroOptions.isNotEmpty) 'heroOptions': heroOptions,
        if (meta.isNotEmpty) 'meta': meta,
        if (templateSourceId != null) 'templateSourceId': templateSourceId,
      };

  @override
  TrainingPackSpot Function(Map<String, dynamic> json) get fromJson =>
      TrainingPackSpot.fromJson;

  /// Converts this spot to a YAML-compatible map.
  ///
  /// The returned map omits empty or null values, mirroring [toJson].
  Map<String, dynamic> toYaml() => toJson();

  /// Creates a [TrainingPackSpot] from a YAML map.
  ///
  /// The method is tolerant to missing fields and invalid values to maintain
  /// backwards compatibility with older pack versions.
  factory TrainingPackSpot.fromYaml(Map yaml) {
    final map = <String, dynamic>{};
    yaml.forEach((k, v) => map[k.toString()] = v);

    map['type'] = yaml['type']?.toString() ?? 'quiz';

    final board = <String>[
      for (final c in (yaml['board'] as List? ?? [])) c.toString()
    ];
    if (board.length >= 3 && board.length <= 5) map['board'] = board;

    final street = (yaml['street'] as num?)?.toInt() ?? 0;
    if (street >= 1 && street <= 3) map['street'] = street;

    final villain = yaml['villainAction']?.toString();
    if (villain != null && ['none', 'check', 'bet'].contains(villain)) {
      map['villainAction'] = villain;
    }

    final heroOptions = <String>[
      for (final o in (yaml['heroOptions'] as List? ?? [])) o.toString()
    ];
    if (heroOptions.isNotEmpty) map['heroOptions'] = heroOptions;

    if (yaml['meta'] is Map) {
      map['meta'] = Map<String, dynamic>.from(yaml['meta']);
    }

    return TrainingPackSpot.fromJson(Map<String, dynamic>.from(map));
  }

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
          type == other.type &&
          title == other.title &&
          note == other.note &&
          hand == other.hand &&
          const ListEquality().equals(tags, other.tags) &&
          const ListEquality().equals(categories, other.categories) &&
          pinned == other.pinned &&
          dirty == other.dirty &&
          priority == other.priority &&
          isNew == other.isNew &&
          evalResult == other.evalResult &&
          correctAction == other.correctAction &&
          explanation == other.explanation &&
          image == other.image &&
          streetMode == other.streetMode &&
          const ListEquality().equals(board, other.board) &&
          street == other.street &&
          villainAction == other.villainAction &&
          const ListEquality().equals(heroOptions, other.heroOptions) &&
          const DeepCollectionEquality().equals(meta, other.meta) &&
          templateSourceId == other.templateSourceId;

  @override
  int get hashCode => Object.hashAll([
        id,
        type,
        title,
        note,
        hand,
        const ListEquality().hash(tags),
        const ListEquality().hash(categories),
        pinned,
        dirty,
        priority,
        isNew,
        evalResult,
        correctAction,
        explanation,
        image,
        streetMode,
        const ListEquality().hash(board),
        street,
        villainAction,
        const ListEquality().hash(heroOptions),
        const DeepCollectionEquality().hash(meta),
        templateSourceId,
      ]);
}

extension TrainingPackSpotStreet on TrainingPackSpot {
  int get street {
    if (this.street > 0) return this.street;
    final n = hand.board.length;
    if (n >= 5) return 3;
    if (n == 4) return 2;
    if (n >= 3) return 1;
    return 0;
  }
}

import 'hand_data.dart';
import '../evaluation_result.dart';
import '../copy_with_mixin.dart';
import '../action_entry.dart';
import '../training_spot.dart';
import '../spot_model.dart';
import 'hero_position.dart';
import '../card_model.dart';
import 'package:uuid/uuid.dart';
import '../../services/inline_theory_linker.dart';

class TrainingPackSpot with CopyWithMixin<TrainingPackSpot> implements SpotModel {
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
  int priority;

  /// Ephemeral flag — used only in RAM to highlight freshly imported spots.
  /// Never written to / read from JSON.
  bool isNew;

  EvaluationResult? evalResult;
  String? correctAction;
  String? explanation;
  List<String> board;
  int street;
  String? villainAction;
  List<String> heroOptions;
  Map<String, dynamic> meta;

  /// Optional reference to the template spot that produced this variation.
  String? templateSourceId;

  /// Optional reference to a theory lesson matched by tags.
  ///
  /// When present, this value is serialized to `inlineTheoryId` in YAML and
  /// links the spot to a [TheoryMiniLessonNode].
  String? inlineTheoryId;

  /// Ephemeral link to a related theory lesson.
  ///
  /// This field is populated at runtime by [AutoSpotTheoryInjectorService]
  /// and is never serialized.
  InlineTheoryLink? theoryLink;

  TrainingPackSpot({
    required this.id,
    HandData? hand,
    List<String>? tags,
    List<String>? categories,
    this.type = 'quiz',
    this.title = '',
    this.note = '',
    this.isNew = false,
    this.pinned = false,
    this.priority = 3,
    this.evalResult,
    this.correctAction,
    this.explanation,
    List<String>? board,
    this.street = 0,
    this.villainAction,
    List<String>? heroOptions,
    Map<String, dynamic>? meta,
    DateTime? editedAt,
    DateTime? createdAt,
    this.templateSourceId,
    this.inlineTheoryId,
  }) : hand = hand ?? HandData(),
       tags = tags != null ? List<String>.from(tags) : <String>[],
       categories = categories != null
           ? List<String>.from(categories)
           : <String>[],
       board = board != null ? List<String>.from(board) : <String>[],
       heroOptions = heroOptions != null
           ? List<String>.from(heroOptions)
           : <String>[],
       meta = meta != null
           ? Map<String, dynamic>.from(meta)
           : <String, dynamic>{},
       editedAt = editedAt ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  factory TrainingPackSpot.fromJson(Map<String, dynamic> j) => TrainingPackSpot(
    id: j['id']?.toString() ?? '',
    hand: j['hand'] != null
        ? HandData.fromJson(Map<String, dynamic>.from(j['hand']))
        : null,
    tags: (j['tags'] as List?)?.map((e) => e.toString()).toList(),
    categories: (j['categories'] as List?)?.map((e) => e.toString()).toList(),
    type: j['type']?.toString() ?? 'quiz',
    title: j['title']?.toString() ?? '',
    note: j['note']?.toString() ?? '',
    pinned: j['pinned'] == true,
    priority: (j['priority'] as num?)?.toInt() ?? 3,
    evalResult: j['evalResult'] != null
        ? EvaluationResult.fromJson(Map<String, dynamic>.from(j['evalResult']))
        : null,
    correctAction: j['correctAction']?.toString(),
    explanation: j['explanation']?.toString(),
    board: (j['board'] as List?)?.map((c) => c.toString()).toList(),
    street: (j['street'] as num?)?.toInt(),
    villainAction: j['villainAction']?.toString(),
    heroOptions: (j['heroOptions'] as List?)?.map((a) => a.toString()).toList(),
    meta: j['meta'] is Map ? Map<String, dynamic>.from(j['meta']) : null,
    editedAt: DateTime.tryParse(j['editedAt']?.toString() ?? ''),
    createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? ''),
    templateSourceId: j['templateSourceId']?.toString(),
    inlineTheoryId: j['inlineTheoryId']?.toString(),
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
      actions
          .putIfAbsent(a.street, () => [])
          .add(
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
      heroOptions: heroOptions,
    );
  }

  Map<String, dynamic> _serialize({bool includeInlineTheoryId = false}) => {
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
        if (priority != 3) 'priority': priority,
        if (evalResult != null) 'evalResult': evalResult!.toJson(),
        if (correctAction != null) 'correctAction': correctAction,
        if (explanation != null) 'explanation': explanation,
        if (board.isNotEmpty) 'board': board,
        if (street > 0) 'street': street,
        if (villainAction != null) 'villainAction': villainAction,
        if (heroOptions.isNotEmpty) 'heroOptions': heroOptions,
        if (meta.isNotEmpty) 'meta': meta,
        if (templateSourceId != null) 'templateSourceId': templateSourceId,
        if (includeInlineTheoryId && inlineTheoryId != null)
          'inlineTheoryId': inlineTheoryId,
      };

  @override
  Map<String, dynamic> toJson() => _serialize();

  /// Converts this spot to a YAML-compatible map.
  ///
  /// The returned map omits empty or null values, mirroring [toJson].
  Map<String, dynamic> toYaml() => _serialize(includeInlineTheoryId: true);

  @override
  TrainingPackSpot copyWith(Map<String, dynamic> changes) {
    final data = _serialize(includeInlineTheoryId: true);
    data.addAll(changes);
    return TrainingPackSpot.fromJson(data);
  }

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

    final board = (yaml['board'] as List?)?.map((c) => c.toString()).toList();
    if (board != null && board.length >= 3 && board.length <= 5) {
      map['board'] = board;
    }

    final street = (yaml['street'] as num?)?.toInt();
    if (street != null && street >= 1 && street <= 3) {
      map['street'] = street;
    }

    final villain = yaml['villainAction']?.toString();
    if (villain != null && ['none', 'check', 'bet'].contains(villain)) {
      map['villainAction'] = villain;
    }

    final heroOptions = (yaml['heroOptions'] as List?)
        ?.map((o) => o.toString())
        .toList();
    if (heroOptions != null && heroOptions.isNotEmpty) {
      map['heroOptions'] = heroOptions;
    }

    if (yaml['meta'] is Map) {
      map['meta'] = Map<String, dynamic>.from(yaml['meta']);
    }

    final inlineId = yaml['inlineTheoryId']?.toString();
    if (inlineId?.isNotEmpty == true) {
      map['inlineTheoryId'] = inlineId;
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
          priority == other.priority &&
          isNew == other.isNew &&
          evalResult == other.evalResult &&
          correctAction == other.correctAction &&
          explanation == other.explanation &&
          const ListEquality().equals(board, other.board) &&
          street == other.street &&
          villainAction == other.villainAction &&
          const ListEquality().equals(heroOptions, other.heroOptions) &&
          const DeepCollectionEquality().equals(meta, other.meta) &&
          templateSourceId == other.templateSourceId &&
          inlineTheoryId == other.inlineTheoryId;

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
    priority,
    isNew,
    evalResult,
    correctAction,
    explanation,
    const ListEquality().hash(board),
    street,
    villainAction,
    const ListEquality().hash(heroOptions),
    const DeepCollectionEquality().hash(meta),
    templateSourceId,
    inlineTheoryId,
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

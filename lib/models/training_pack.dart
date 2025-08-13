import 'saved_hand.dart';
import 'training_spot.dart';
import 'session_task_result.dart';
import 'game_type.dart';
import 'package:uuid/uuid.dart';
import 'package:json_annotation/json_annotation.dart';

part 'training_pack.g.dart';

GameType parseGameType(dynamic v) {
  final s = (v as String? ?? '').toLowerCase();
  if (s.startsWith('tour')) return GameType.tournament;
  return GameType.cash;
}

@JsonSerializable(explicitToJson: true)
class TrainingSessionResult {
  final DateTime date;
  final int total;
  final int correct;
  final List<SessionTaskResult> tasks;

  TrainingSessionResult({
    required this.date,
    required this.total,
    required this.correct,
    List<SessionTaskResult>? tasks,
  }) : tasks = tasks ?? [];

  factory TrainingSessionResult.fromJson(Map<String, dynamic> json) =>
      _$TrainingSessionResultFromJson(json);
  Map<String, dynamic> toJson() => _$TrainingSessionResultToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TrainingPack {
  final String id;
  final String name;
  final String description;
  final String category;
  final GameType gameType;
  final String colorTag;
  final bool isBuiltIn;
  final List<String> tags;
  final List<SavedHand> hands;
  final List<TrainingSpot> spots;
  final int difficulty;
  final List<TrainingSessionResult> history;
  final DateTime createdAt;

  TrainingPack({
    String? id,
    required this.name,
    required this.description,
    this.category = 'Uncategorized',
    this.gameType = GameType.cash,
    this.colorTag = '#2196F3',
    this.isBuiltIn = false,
    List<String>? tags,
    required this.hands,
    List<TrainingSpot>? spots,
    this.difficulty = 1,
    List<TrainingSessionResult>? history,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        tags = tags ?? const [],
        spots = spots ?? const [],
        history = history ?? [],
        createdAt = createdAt ?? DateTime.now();

  int get solved => history.isNotEmpty ? history.last.correct : 0;
  int get lastAttempted => history.isNotEmpty ? history.last.total : 0;
  DateTime get lastAttemptDate => history.isNotEmpty
      ? history.last.date
      : DateTime.fromMillisecondsSinceEpoch(0);

  factory TrainingPack.fromJson(Map<String, dynamic> json) =>
      _$TrainingPackFromJson(json);
  Map<String, dynamic> toJson() => _$TrainingPackToJson(this);

  TrainingPack copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    GameType? gameType,
    String? colorTag,
    bool? isBuiltIn,
    List<String>? tags,
    List<SavedHand>? hands,
    List<TrainingSpot>? spots,
    int? difficulty,
    List<TrainingSessionResult>? history,
    DateTime? createdAt,
  }) {
    return TrainingPack(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      gameType: gameType ?? this.gameType,
      colorTag: colorTag ?? this.colorTag,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      tags: tags ?? List<String>.from(this.tags),
      hands: hands ?? List<SavedHand>.from(this.hands),
      spots: spots ?? List<TrainingSpot>.from(this.spots),
      difficulty: difficulty ?? this.difficulty,
      history: history ?? List<TrainingSessionResult>.from(this.history),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

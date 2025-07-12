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

String _gameTypeToJson(GameType v) => v.name;

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
  @JsonKey(fromJson: parseGameType, toJson: _gameTypeToJson)
  final GameType gameType;
  final String colorTag;
  final bool isBuiltIn;
  final List<String> tags;
  final List<SavedHand> hands;
  final List<TrainingSpot> spots;
  final int difficulty;
  final List<TrainingSessionResult> history;

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
  })  : id = id ?? const Uuid().v4(),
        tags = tags ?? const [],
        spots = spots ?? const [],
        history = history ?? [];

  int get solved => history.isNotEmpty ? history.last.correct : 0;
  int get lastAttempted => history.isNotEmpty ? history.last.total : 0;
  DateTime get lastAttemptDate =>
      history.isNotEmpty ? history.last.date : DateTime.fromMillisecondsSinceEpoch(0);

  factory TrainingPack.fromJson(Map<String, dynamic> json) =>
      _$TrainingPackFromJson(json);
  Map<String, dynamic> toJson() => _$TrainingPackToJson(this);
}

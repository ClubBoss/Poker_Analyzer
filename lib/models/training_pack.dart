import 'saved_hand.dart';
import 'training_spot.dart';
import 'session_task_result.dart';
import 'game_type.dart';
import 'package:uuid/uuid.dart';

GameType parseGameType(dynamic v) {
  final s = (v as String? ?? '').toLowerCase();
  if (s.startsWith('tour')) return GameType.tournament;
  return GameType.cash;
}

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

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'total': total,
        'correct': correct,
        'tasks': [for (final t in tasks) t.toJson()],
      };

  static TrainingSessionResult fromJson(Map<String, dynamic> json) {
    return TrainingSessionResult(
      date: DateTime.parse(json['date']),
      total: json['total'],
      correct: json['correct'],
      tasks: [
        for (final t in (json['tasks'] as List? ?? []))
          SessionTaskResult.fromJson(Map<String, dynamic>.from(t))
      ],
    );
  }
}

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'gameType': gameType.name,
        'colorTag': colorTag,
        'isBuiltIn': isBuiltIn,
        if (tags.isNotEmpty) 'tags': tags,
        'hands': [for (final h in hands) h.toJson()],
        if (spots.isNotEmpty) 'spots': [for (final s in spots) s.toJson()],
        'difficulty': difficulty,
        'history': [for (final r in history) r.toJson()],
      };

  factory TrainingPack.fromJson(Map<String, dynamic> json) => TrainingPack(
        id: json['id'] as String?,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? 'Uncategorized',
        gameType: parseGameType(json['gameType']),
        colorTag: json['colorTag'] as String? ?? '#2196F3',
        isBuiltIn: json['isBuiltIn'] as bool? ?? false,
        tags: [for (final t in (json['tags'] as List? ?? [])) t as String],
        hands: [
          for (final h in (json['hands'] as List? ?? []))
            SavedHand.fromJson(h as Map<String, dynamic>)
        ],
        spots: [
          for (final s in (json['spots'] as List? ?? []))
            TrainingSpot.fromJson(Map<String, dynamic>.from(s as Map))
        ],
        difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
        history: [
          for (final r in (json['history'] as List? ?? []))
            TrainingSessionResult.fromJson(r as Map<String, dynamic>)
        ],
      );
}

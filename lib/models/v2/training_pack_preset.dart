import 'hero_position.dart';
import '../game_type.dart';
import '../training_spot.dart';

class TrainingPackPreset {
  final String id;
  final String name;
  final String description;
  final String category;
  final GameType gameType;
  final int heroBbStack;
  final List<int> playerStacksBb;
  final HeroPosition heroPos;
  final int spotCount;
  final int bbCallPct;
  final int anteBb;
  final List<String>? heroRange;
  final DateTime createdAt;
  final List<TrainingSpot> spots;

  TrainingPackPreset({
    required this.id,
    required this.name,
    this.description = '',
    this.category = '',
    this.gameType = GameType.tournament,
    this.heroBbStack = 10,
    List<int>? playerStacksBb,
    this.heroPos = HeroPosition.sb,
    this.spotCount = 20,
    this.bbCallPct = 20,
    this.anteBb = 0,
    this.heroRange,
    DateTime? createdAt,
    List<TrainingSpot>? spots,
  })  : playerStacksBb = playerStacksBb ?? const [10, 10],
        createdAt = createdAt ?? DateTime.now(),
        spots = spots ?? const [];

  factory TrainingPackPreset.fromJson(Map<String, dynamic> j) =>
      TrainingPackPreset(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
        gameType: GameType.values.firstWhere(
          (e) => e.name == j['gameType'],
          orElse: () => GameType.tournament,
        ),
        heroBbStack: j['heroBbStack'] as int? ?? 10,
        playerStacksBb: [
          for (final v in (j['playerStacksBb'] as List? ?? [10, 10]))
            (v as num).toInt(),
        ],
        heroPos: HeroPosition.values.firstWhere(
          (e) => e.name == j['heroPos'],
          orElse: () => HeroPosition.sb,
        ),
        spotCount: j['spotCount'] as int? ?? 20,
        bbCallPct: j['bbCallPct'] as int? ?? 20,
        anteBb: j['anteBb'] as int? ?? 0,
        heroRange: (j['heroRange'] as List?)?.map((e) => e as String).toList(),
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
        category: j['category'] as String? ?? '',
        spots: [
          for (final s in (j['spots'] as List? ?? []))
            TrainingSpot.fromJson(Map<String, dynamic>.from(s)),
        ],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'gameType': gameType.name,
        'heroBbStack': heroBbStack,
        'playerStacksBb': playerStacksBb,
        'heroPos': heroPos.name,
        'spotCount': spotCount,
        'bbCallPct': bbCallPct,
        'anteBb': anteBb,
        if (heroRange != null) 'heroRange': heroRange,
        'createdAt': createdAt.toIso8601String(),
        if (spots.isNotEmpty) 'spots': [for (final s in spots) s.toJson()],
      };
}

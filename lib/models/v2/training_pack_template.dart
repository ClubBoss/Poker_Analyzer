import 'training_pack_spot.dart';
import 'hero_position.dart';
import '../game_type.dart';
import '../training_pack.dart' show parseGameType;
import '../../services/pack_generator_service.dart';

class TrainingPackTemplate {
  final String id;
  String name;
  String description;
  GameType gameType;
  List<TrainingPackSpot> spots;
  List<String> tags;
  int heroBbStack;
  List<int> playerStacksBb;
  HeroPosition heroPos;
  int spotCount;
  int bbCallPct;
  int anteBb;
  List<String>? heroRange;
  final DateTime createdAt;

  TrainingPackTemplate({
    required this.id,
    required this.name,
    this.description = '',
    this.gameType = GameType.tournament,
    List<TrainingPackSpot>? spots,
    List<String>? tags,
    this.heroBbStack = 10,
    List<int>? playerStacksBb,
    this.heroPos = HeroPosition.sb,
    this.spotCount = 20,
    this.bbCallPct = 20,
    this.anteBb = 0,
    this.heroRange,
    DateTime? createdAt,
  })  : spots = spots ?? [],
        tags = tags ?? [],
        playerStacksBb = playerStacksBb ?? const [10, 10],
        createdAt = createdAt ?? DateTime.now();

  TrainingPackTemplate copyWith({
    String? id,
    String? name,
    String? description,
    GameType? gameType,
    List<TrainingPackSpot>? spots,
    List<String>? tags,
    int? heroBbStack,
    List<int>? playerStacksBb,
    HeroPosition? heroPos,
    int? spotCount,
    int? bbCallPct,
    int? anteBb,
    List<String>? heroRange,
    DateTime? createdAt,
  }) {
    return TrainingPackTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      gameType: gameType ?? this.gameType,
      spots: spots ?? List<TrainingPackSpot>.from(this.spots),
      tags: tags ?? List<String>.from(this.tags),
      heroBbStack: heroBbStack ?? this.heroBbStack,
      playerStacksBb: playerStacksBb ?? List<int>.from(this.playerStacksBb),
      heroPos: heroPos ?? this.heroPos,
      spotCount: spotCount ?? this.spotCount,
      bbCallPct: bbCallPct ?? this.bbCallPct,
      anteBb: anteBb ?? this.anteBb,
      heroRange: heroRange ?? this.heroRange,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory TrainingPackTemplate.fromJson(Map<String, dynamic> json) {
    return TrainingPackTemplate(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      gameType: parseGameType(json['gameType']),
      spots: [
        for (final s in (json['spots'] as List? ?? []))
          TrainingPackSpot.fromJson(Map<String, dynamic>.from(s))
      ],
      tags: [for (final t in (json['tags'] as List? ?? [])) t as String],
      heroBbStack: json['heroBbStack'] as int? ?? 10,
      playerStacksBb: [
        for (final v in (json['playerStacksBb'] as List? ?? [10, 10]))
          (v as num).toInt()
      ],
      heroPos: HeroPosition.values.firstWhere(
        (e) => e.name == json['heroPos'],
        orElse: () => HeroPosition.sb,
      ),
      spotCount: json['spotCount'] as int? ?? 20,
      bbCallPct: json['bbCallPct'] as int? ?? 20,
      anteBb: json['anteBb'] as int? ?? 0,
      heroRange: (json['heroRange'] as List?)?.map((e) => e as String).toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'gameType': gameType.name,
        if (spots.isNotEmpty) 'spots': [for (final s in spots) s.toJson()],
        if (tags.isNotEmpty) 'tags': tags,
        if (heroRange != null) 'heroRange': heroRange,
        'heroBbStack': heroBbStack,
        'playerStacksBb': playerStacksBb,
        'heroPos': heroPos.name,
        'spotCount': spotCount,
        'bbCallPct': bbCallPct,
        'anteBb': anteBb,
        'createdAt': createdAt.toIso8601String(),
      };

  Future<List<TrainingPackSpot>> generateSpots() async {
    final range = heroRange ?? PackGeneratorService.topNHands(25).toList();
    final tpl = await PackGeneratorService.generatePushFoldPack(
      id: id,
      name: name,
      heroBbStack: heroBbStack,
      playerStacksBb: playerStacksBb,
      heroPos: heroPos,
      heroRange: range,
      bbCallPct: bbCallPct,
      anteBb: anteBb,
    );
    return tpl.spots.take(spotCount).toList();
  }
}

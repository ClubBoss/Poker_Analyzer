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
  double minEvForCorrect;
  List<String>? heroRange;
  final DateTime createdAt;
  DateTime? lastGeneratedAt;
  Map<String, dynamic> meta;

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
    this.minEvForCorrect = 0.01,
    this.heroRange,
    DateTime? createdAt,
    this.lastGeneratedAt,
    Map<String, dynamic>? meta,
  })  : spots = spots ?? [],
        tags = tags ?? [],
        playerStacksBb = playerStacksBb ?? const [10, 10],
        meta = meta ?? {},
        createdAt = createdAt ?? DateTime.now() {
    recountCoverage();
  }

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
    double? minEvForCorrect,
    List<String>? heroRange,
    DateTime? createdAt,
    DateTime? lastGeneratedAt,
    Map<String, dynamic>? meta,
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
      minEvForCorrect: minEvForCorrect ?? this.minEvForCorrect,
      heroRange: heroRange ?? this.heroRange,
      createdAt: createdAt ?? this.createdAt,
      lastGeneratedAt: lastGeneratedAt ?? this.lastGeneratedAt,
      meta: meta ?? Map<String, dynamic>.from(this.meta),
    );
  }

  factory TrainingPackTemplate.fromJson(Map<String, dynamic> json) {
    final tpl = TrainingPackTemplate(
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
      minEvForCorrect: (json['minEvForCorrect'] as num?)?.toDouble() ?? 0.01,
      heroRange: (json['heroRange'] as List?)?.map((e) => e as String).toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      lastGeneratedAt:
          DateTime.tryParse(json['lastGeneratedAt'] as String? ?? ''),
      meta: json['meta'] != null ? Map<String, dynamic>.from(json['meta']) : {},
    );
    if (!tpl.meta.containsKey('evCovered') || !tpl.meta.containsKey('icmCovered')) {
      tpl.recountCoverage();
    }
    return tpl;
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
        'minEvForCorrect': minEvForCorrect,
        'createdAt': createdAt.toIso8601String(),
        if (lastGeneratedAt != null)
          'lastGeneratedAt': lastGeneratedAt!.toIso8601String(),
        if (meta.isNotEmpty) 'meta': meta,
      };

  int get evCovered => meta['evCovered'] as int? ?? 0;
  int get icmCovered => meta['icmCovered'] as int? ?? 0;

  void recountCoverage([List<TrainingPackSpot>? all]) {
    final list = all ?? spots;
    int ev = 0;
    int icm = 0;
    for (final s in list) {
      if (s.heroEv != null) ev++;
      if (s.heroIcmEv != null) icm++;
    }
    meta['evCovered'] = ev;
    meta['icmCovered'] = icm;
  }

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

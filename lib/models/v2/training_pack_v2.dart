import 'training_pack_spot.dart';
import '../game_type.dart';
import '../../core/training/engine/training_type_engine.dart';
import 'training_pack_template_v2.dart' show TrainingPackTemplateV2;

class TrainingPackV2 {
  final String id;
  final String sourceTemplateId;
  String name;
  String description;
  List<String> tags;
  final TrainingType type;
  List<TrainingPackSpot> spots;
  int spotCount;
  final DateTime generatedAt;
  GameType gameType;
  int bb;
  List<String> positions;
  int difficulty;
  Map<String, dynamic> meta;

  TrainingPackV2({
    required this.id,
    required this.sourceTemplateId,
    required this.name,
    this.description = '',
    List<String>? tags,
    required this.type,
    List<TrainingPackSpot>? spots,
    this.spotCount = 0,
    DateTime? generatedAt,
    this.gameType = GameType.cash,
    this.bb = 0,
    List<String>? positions,
    this.difficulty = 0,
    Map<String, dynamic>? meta,
  })  : tags = tags ?? [],
        spots = spots ?? [],
        positions = positions ?? [],
        generatedAt = generatedAt ?? DateTime.now(),
        meta = meta ?? {};

  factory TrainingPackV2.fromJson(Map<String, dynamic> j) => TrainingPackV2(
        id: j['id'] as String? ?? '',
        sourceTemplateId: j['sourceTemplateId'] as String? ?? '',
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
        tags: [for (final t in (j['tags'] as List? ?? [])) t.toString()],
        type: TrainingType.values.firstWhere(
          (e) => e.name == j['type'],
          orElse: () => TrainingType.pushFold,
        ),
        spots: [
          for (final s in (j['spots'] as List? ?? []))
            TrainingPackSpot.fromJson(Map<String, dynamic>.from(s)),
        ],
        spotCount: j['spotCount'] as int? ?? 0,
        generatedAt: DateTime.tryParse(j['generatedAt'] as String? ?? '') ??
            DateTime.now(),
        gameType: parseGameType(j['gameType']),
        bb: (j['bb'] as num?)?.toInt() ?? 0,
        positions: [
          for (final p in (j['positions'] as List? ?? [])) p.toString()
        ],
        difficulty: (j['difficulty'] as num?)?.toInt() ?? 0,
        meta: j['meta'] != null ? Map<String, dynamic>.from(j['meta']) : {},
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceTemplateId': sourceTemplateId,
        'name': name,
        'description': description,
        if (tags.isNotEmpty) 'tags': tags,
        'type': type.name,
        if (spots.isNotEmpty) 'spots': [for (final s in spots) s.toJson()],
        'spotCount': spotCount,
        'generatedAt': generatedAt.toIso8601String(),
        'gameType': gameType.name,
        'bb': bb,
        if (positions.isNotEmpty) 'positions': positions,
        'difficulty': difficulty,
        if (meta.isNotEmpty) 'meta': meta,
      };

  factory TrainingPackV2.fromTemplate(TrainingPackTemplateV2 t, String id) {
    final spotList =
        (t.dynamicSpots.isNotEmpty || t.meta['dynamicParams'] is Map)
            ? t.generateDynamicSpotSamples()
            : t.spots;
    return TrainingPackV2(
      id: id,
      sourceTemplateId: t.id,
      name: t.name,
      description: t.description,
      tags: List<String>.from(t.tags),
      type: t.trainingType,
      spots: [for (final s in spotList) TrainingPackSpot.fromJson(s.toJson())],
      spotCount: spotList.length,
      generatedAt: DateTime.now(),
      gameType: t.gameType,
      bb: t.bb,
      positions: List<String>.from(t.positions),
      meta: Map<String, dynamic>.from(t.meta),
    );
  }
}

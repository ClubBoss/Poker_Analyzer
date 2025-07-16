import 'dart:convert';
import 'package:yaml/yaml.dart';

import '../../core/training/generation/yaml_reader.dart';
import '../game_type.dart';
import '../training_pack.dart' show parseGameType;
import '../../core/training/engine/training_type_engine.dart';
import 'training_pack_spot.dart';
import 'spot_template.dart';

class TrainingPackTemplateV2 {
  final String id;
  String name;
  String description;
  String goal;
  String? audience;
  List<String> tags;
  final TrainingType type;
  List<SpotTemplate> spots;
  int spotCount;
  final DateTime created;
  GameType gameType;
  int bb;
  List<String> positions;
  Map<String, dynamic> meta;

  TrainingPackTemplateV2({
    required this.id,
    required this.name,
    this.description = '',
    this.goal = '',
    this.audience,
    List<String>? tags,
    required this.type,
    List<SpotTemplate>? spots,
    this.spotCount = 0,
    DateTime? created,
    this.gameType = GameType.cash,
    this.bb = 0,
    List<String>? positions,
    Map<String, dynamic>? meta,
  })  : tags = tags ?? [],
        spots = spots ?? [],
        positions = positions ?? [],
        created = created ?? DateTime.now(),
        meta = meta ?? {};

  factory TrainingPackTemplateV2.fromJson(Map<String, dynamic> j) =>
      TrainingPackTemplateV2(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
        goal: j['goal'] as String? ?? '',
        audience: j['audience'] as String? ??
            (j['meta'] is Map ? (j['meta']['audience'] as String?) : null),
        tags: [for (final t in (j['tags'] as List? ?? [])) t.toString()],
        type: TrainingType.values.firstWhere(
          (e) => e.name == j['type'],
          orElse: () => TrainingType.pushfold,
        ),
        spots: [
          for (final s in (j['spots'] as List? ?? []))
            TrainingPackSpot.fromJson(Map<String, dynamic>.from(s))
        ],
        spotCount: j['spotCount'] as int? ?? (j['spots'] as List? ?? []).length,
        created: DateTime.tryParse(j['created'] as String? ?? '') ?? DateTime.now(),
        gameType: parseGameType(j['gameType']),
        bb: (j['bb'] as num?)?.toInt() ?? 0,
        positions: [for (final p in (j['positions'] as List? ?? [])) p.toString()],
        meta: j['meta'] != null ? Map<String, dynamic>.from(j['meta']) : {},
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        if (goal.isNotEmpty) 'goal': goal,
        if (audience != null && audience!.isNotEmpty) 'audience': audience,
        if (tags.isNotEmpty) 'tags': tags,
        'type': type.name,
        if (spots.isNotEmpty) 'spots': [for (final s in spots) s.toJson()],
        'spotCount': spotCount,
        'created': created.toIso8601String(),
        'gameType': gameType.name,
        'bb': bb,
        if (positions.isNotEmpty) 'positions': positions,
        if (meta.isNotEmpty) 'meta': meta,
      };

  factory TrainingPackTemplateV2.fromYaml(String source) {
    final map = const YamlReader().read(source);
    return TrainingPackTemplateV2.fromJson(map);
  }

  String toYaml() => const YamlEncoder().convert(toJson());

  factory TrainingPackTemplateV2.fromTemplate(
    TrainingPackTemplate template, {
    required TrainingType type,
  }) =>
      TrainingPackTemplateV2(
        id: template.id,
        name: template.name,
        description: template.description,
        goal: template.goal,
        audience: template.meta['audience'] as String?,
        tags: List<String>.from(template.tags),
        type: type,
        spots: List<SpotTemplate>.from(template.spots),
        spotCount: template.spotCount,
        created: template.createdAt,
        gameType: template.gameType,
        bb: template.heroBbStack,
        positions: [template.heroPos.name],
        meta: Map<String, dynamic>.from(template.meta),
      );
}

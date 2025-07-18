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
  String? category;
  TrainingType trainingType;
  List<SpotTemplate> spots;
  int spotCount;
  final DateTime created;
  GameType gameType;
  int bb;
  List<String> positions;
  Map<String, dynamic> meta;
  bool recommended;

  TrainingPackTemplateV2({
    required this.id,
    required this.name,
    this.description = '',
    this.goal = '',
    this.audience,
    List<String>? tags,
    this.category,
    required this.trainingType,
    List<SpotTemplate>? spots,
    this.spotCount = 0,
    DateTime? created,
    this.gameType = GameType.cash,
    this.bb = 0,
    List<String>? positions,
    Map<String, dynamic>? meta,
    this.recommended = false,
  })  : tags = tags ?? [],
        spots = spots ?? [],
        positions = positions ?? [],
        created = created ?? DateTime.now(),
        meta = meta ?? {} {
    category ??= this.tags.isNotEmpty ? this.tags.first : null;
  }

  factory TrainingPackTemplateV2.fromJson(Map<String, dynamic> j) {
    final tpl = TrainingPackTemplateV2(
      id: j['id'] as String? ?? '',
      name: j['name'] as String? ?? '',
      description: j['description'] as String? ?? '',
      goal: j['goal'] as String? ?? '',
      audience: j['audience'] as String? ??
          (j['meta'] is Map ? (j['meta']['audience'] as String?) : null),
      tags: [for (final t in (j['tags'] as List? ?? [])) t.toString()],
      category: (j['category'] ?? j['mainTag'])?.toString(),
      trainingType: TrainingType.values.firstWhere(
        (e) => e.name == (j['trainingType'] ?? j['type']),
        orElse: () => TrainingType.pushFold,
      ),
      spots: [
        for (final s in (j['spots'] as List? ?? []))
          TrainingPackSpot.fromJson(Map<String, dynamic>.from(s))
      ],
      spotCount: j['spotCount'] as int? ?? (j['spots'] as List? ?? []).length,
      created:
          DateTime.tryParse(j['created'] as String? ?? '') ?? DateTime.now(),
      gameType: parseGameType(j['gameType']),
      bb: (j['bb'] as num?)?.toInt() ?? 0,
      positions: [
        for (final p in (j['positions'] as List? ?? [])) p.toString()
      ],
      meta: j['meta'] != null ? Map<String, dynamic>.from(j['meta']) : {},
      recommended: j['recommended'] as bool? ??
          (j['meta'] is Map ? j['meta']['recommended'] == true : false),
    );
    tpl.category ??= tpl.tags.isNotEmpty ? tpl.tags.first : null;
    if ((j['trainingType'] ?? j['type']) == null) {
      tpl.trainingType = const TrainingTypeEngine().detectTrainingType(tpl);
    }
    return tpl;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        if (goal.isNotEmpty) 'goal': goal,
        if (audience != null && audience!.isNotEmpty) 'audience': audience,
        if (tags.isNotEmpty) 'tags': tags,
        if (category != null && category!.isNotEmpty) 'category': category,
        'trainingType': trainingType.name,
        if (spots.isNotEmpty) 'spots': [for (final s in spots) s.toJson()],
        'spotCount': spotCount,
        'created': created.toIso8601String(),
        'gameType': gameType.name,
        'bb': bb,
        if (positions.isNotEmpty) 'positions': positions,
        if (meta.isNotEmpty) 'meta': meta,
        if (recommended) 'recommended': true,
      };

  factory TrainingPackTemplateV2.fromYaml(String source) {
    final map = const YamlReader().read(source);
    return TrainingPackTemplateV2.fromJson(map);
  }

  factory TrainingPackTemplateV2.fromYamlAuto(String source) {
    final map = const YamlReader().read(source);
    final tpl = TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(map));
    if ((map['trainingType'] ?? map['type']) == null) {
      tpl.trainingType = const TrainingTypeEngine().detectTrainingType(tpl);
    }
    return tpl;
  }

  /// Serializes this template to a YAML string. The resulting YAML always
  /// contains the training type under `meta.trainingType` to improve
  /// portability of exported packs.
  String toYamlString() {
    final map = toJson();

    // Ensure the training type field is present. If somehow missing in the
    // map (older objects) detect it automatically.
    var typeName = map['trainingType'] as String?;
    if (typeName == null || typeName.isEmpty) {
      final detected = const TrainingTypeEngine().detectTrainingType(this);
      typeName = detected.name;
      map['trainingType'] = typeName;
    }

    final metaMap = Map<String, dynamic>.from(map['meta'] ?? {});
    metaMap['trainingType'] = typeName;
    map['meta'] = metaMap;

    return const YamlEncoder().convert(map);
  }

  // Backwards compatible alias used across the code base.
  String toYaml() => toYamlString();

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
        category: template.tags.isNotEmpty ? template.tags.first : null,
        trainingType: type,
        spots: List<SpotTemplate>.from(template.spots),
        spotCount: template.spotCount,
        created: template.createdAt,
        gameType: template.gameType,
        bb: template.heroBbStack,
        positions: [template.heroPos.name],
        meta: Map<String, dynamic>.from(template.meta),
        recommended: template.recommended,
      );
}

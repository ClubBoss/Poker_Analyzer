import 'dart:convert';
import 'package:yaml/yaml.dart';

import '../../core/training/generation/yaml_reader.dart';
import '../game_type.dart';
import '../training_pack.dart' show parseGameType;
import '../../core/training/engine/training_type_engine.dart';
import 'training_pack_spot.dart';
import 'spot_template.dart';
import 'dynamic_spot_template.dart';
import 'unlock_rules.dart';
import 'hero_position.dart';
import 'training_pack_template.dart' show TrainingPackTemplate;
import '../../services/training_spot_generator_service.dart';

class TrainingPackTemplateV2 {
  final String id;
  String name;
  String description;
  String goal;
  String? audience;
  String? theme;
  List<String> tags;
  String? category;
  TrainingType trainingType;
  List<SpotTemplate> spots;
  int spotCount;
  List<DynamicSpotTemplate> dynamicSpots;
  final DateTime created;
  GameType gameType;
  int bb;
  List<String> positions;
  Map<String, dynamic> meta;
  bool recommended;
  bool requiresTheoryCompleted;
  String? targetStreet;
  UnlockRules? unlockRules;
  double? requiredAccuracy;
  int? minHands;

  // Legacy fields kept for backwards compatibility.
  double? get requiresAccuracy =>
      (meta['requiresAccuracy'] as num?)?.toDouble();
  int? get requiresVolume =>
      (meta['requiresVolume'] as num?)?.toInt();

  /// Ephemeral flag – marks automatically generated packs. Never
  /// serialized to or from disk.
  bool isGeneratedPack;

  /// Ephemeral flag – marks packs created by sampling a larger template.
  /// Never serialized to or from disk.
  bool isSampledPack;

  TrainingPackTemplateV2({
    required this.id,
    required this.name,
    this.description = '',
    this.goal = '',
    this.audience,
    this.theme,
    List<String>? tags,
    this.category,
    required this.trainingType,
    List<SpotTemplate>? spots,
    this.spotCount = 0,
    List<DynamicSpotTemplate>? dynamicSpots,
    DateTime? created,
    this.gameType = GameType.cash,
    this.bb = 0,
    List<String>? positions,
    Map<String, dynamic>? meta,
    this.recommended = false,
    this.requiresTheoryCompleted = false,
    this.targetStreet,
    this.unlockRules,
    this.requiredAccuracy,
    this.minHands,
    bool? isGeneratedPack,
    bool? isSampledPack,
  }) : tags = tags ?? [],
       spots = spots ?? [],
       dynamicSpots = dynamicSpots ?? [],
       positions = positions ?? [],
       created = created ?? DateTime.now(),
       meta = meta ?? {},
       isGeneratedPack = isGeneratedPack ?? false,
       isSampledPack = isSampledPack ?? false {
    if (theme != null) meta['theme'] = theme;
    if (requiredAccuracy != null) meta['requiredAccuracy'] = requiredAccuracy;
    if (minHands != null) meta['minHands'] = minHands;
    category ??= this.tags.isNotEmpty ? this.tags.first : null;
  }

  List<TrainingPackSpot> generateDynamicSpotSamples() {
    if (meta['dynamicParams'] is Map) {
      final m = Map<String, dynamic>.from(meta['dynamicParams']);
      final boardFilter =
          m['boardFilter'] is Map ? Map<String, dynamic>.from(m['boardFilter']) : null;
      final params = SpotGenerationParams(
        position: m['position']?.toString() ?? 'btn',
        villainAction: m['villainAction']?.toString() ?? '',
        handGroup: [
          for (final g in (m['handGroup'] as List? ?? [])) g.toString()
        ],
        count: (m['count'] as num?)?.toInt() ?? 0,
        boardFilter: boardFilter,
      );
      final gen = TrainingSpotGeneratorService().generate(params);
      return [
        for (final s in gen)
          TrainingPackSpot.fromTrainingSpot(
            s,
            villainAction: params.villainAction,
          )
      ];
    }
    final list = <TrainingPackSpot>[];
    for (final d in dynamicSpots) {
      list.addAll(d.generateSpots());
    }
    return list;
  }

  void regenerateDynamicSpots() {
    if (dynamicSpots.isEmpty && meta['dynamicParams'] is! Map) return;
    spots = generateDynamicSpotSamples();
    spotCount = spots.length;
  }

  factory TrainingPackTemplateV2.fromJson(Map<String, dynamic> j) {
    final metaMap = j['meta'] != null ? Map<String, dynamic>.from(j['meta']) : {};

    final dynParams = metaMap['dynamicParams'];
    var dynamicList = <DynamicSpotTemplate>[];
    var spots = <TrainingPackSpot>[];

    if (dynParams is Map) {
      final boardFilter = dynParams['boardFilter'] is Map
          ? Map<String, dynamic>.from(dynParams['boardFilter'])
          : null;
      final params = SpotGenerationParams(
        position: dynParams['position']?.toString() ?? 'btn',
        villainAction: dynParams['villainAction']?.toString() ?? '',
        handGroup: [
          for (final g in (dynParams['handGroup'] as List? ?? [])) g.toString()
        ],
        count: (dynParams['count'] as num?)?.toInt() ?? 0,
        boardFilter: boardFilter,
      );
      final generator = TrainingSpotGeneratorService();
      final genSpots = generator.generate(params);
      spots = [
        for (final s in genSpots)
          TrainingPackSpot.fromTrainingSpot(
            s,
            villainAction: params.villainAction,
          )
      ];
    } else {
      dynamicList = <DynamicSpotTemplate>[
        for (final d in (j['dynamicSpots'] as List? ?? []))
          DynamicSpotTemplate.fromJson(Map<String, dynamic>.from(d)),
      ];

      spots = <TrainingPackSpot>[
        for (final s in (j['spots'] as List? ?? []))
          TrainingPackSpot.fromJson(Map<String, dynamic>.from(s)),
      ];

      if (dynamicList.isNotEmpty) {
        spots = <TrainingPackSpot>[];
        for (final d in dynamicList) {
          spots.addAll(d.generateSpots());
        }
      }
    }

    final tpl = TrainingPackTemplateV2(
      id: j['id'] as String? ?? '',
      name: j['name'] as String? ?? '',
      description: j['description'] as String? ?? '',
      goal: j['goal'] as String? ?? '',
      audience:
          j['audience'] as String? ??
          (j['meta'] is Map ? (j['meta']['audience'] as String?) : null),
      theme: j['meta'] is Map ? (j['meta']['theme'] as String?) : null,
      tags: [for (final t in (j['tags'] as List? ?? [])) t.toString()],
      category: (j['category'] ?? j['mainTag'])?.toString(),
      trainingType: TrainingType.values.firstWhere(
        (e) => e.name == (j['trainingType'] ?? j['type']),
        orElse: () => TrainingType.pushFold,
      ),
      spots: spots,
      spotCount: spots.length,
      created:
          DateTime.tryParse(j['created'] as String? ?? '') ?? DateTime.now(),
      gameType: parseGameType(j['gameType']),
      bb: (j['bb'] as num?)?.toInt() ?? 0,
      positions: [
        for (final p in (j['positions'] as List? ?? [])) p.toString(),
      ],
      meta: metaMap,
      recommended: j['recommended'] as bool? ??
          (j['meta'] is Map ? j['meta']['recommended'] == true : false),
      requiresTheoryCompleted: j['meta'] is Map
          ? j['meta']['requiresTheoryCompleted'] == true
          : false,
      targetStreet: j['targetStreet'] as String?,
      unlockRules: j['unlockRules'] is Map
          ? UnlockRules.fromJson(Map<String, dynamic>.from(j['unlockRules']))
          : null,
      requiredAccuracy: j['meta'] is Map
          ? (j['meta']['requiredAccuracy'] as num?)?.toDouble()
          : null,
      minHands:
          j['meta'] is Map ? (j['meta']['minHands'] as num?)?.toInt() : null,
      dynamicSpots: dynamicList,
    );
    tpl.category ??= tpl.tags.isNotEmpty ? tpl.tags.first : null;
    if (tpl.theme != null) tpl.meta['theme'] = tpl.theme;
    if ((j['trainingType'] ?? j['type']) == null) {
      tpl.trainingType = const TrainingTypeEngine().detectTrainingType(tpl);
    }
    return tpl;
  }

  Map<String, dynamic> toJson() {
    final map = {
      'id': id,
      'name': name,
      'description': description,
      if (goal.isNotEmpty) 'goal': goal,
      if (audience != null && audience!.isNotEmpty) 'audience': audience,
      if (tags.isNotEmpty) 'tags': tags,
      if (category != null && category!.isNotEmpty) 'category': category,
      'trainingType': trainingType.name,
      if (dynamicSpots.isNotEmpty)
        'dynamicSpots': [for (final d in dynamicSpots) d.toJson()]
      else if (spots.isNotEmpty)
        'spots': [for (final s in spots) s.toJson()],
      'spotCount': spotCount,
      'created': created.toIso8601String(),
      'gameType': gameType.name,
      'bb': bb,
      if (positions.isNotEmpty) 'positions': positions,
      if (recommended) 'recommended': true,
      if (targetStreet != null) 'targetStreet': targetStreet,
      if (unlockRules != null) 'unlockRules': unlockRules!.toJson(),
    };
    final metaMap = Map<String, dynamic>.from(meta);
    if (theme != null) metaMap['theme'] = theme;
    if (requiresTheoryCompleted) {
      metaMap['requiresTheoryCompleted'] = true;
    }
    if (requiredAccuracy != null) {
      metaMap['requiredAccuracy'] = requiredAccuracy;
    }
    if (minHands != null) {
      metaMap['minHands'] = minHands;
    }
    if (metaMap.isNotEmpty) map['meta'] = metaMap;
    return map;
  }

  factory TrainingPackTemplateV2.fromYaml(String source) {
    final map = const YamlReader().read(source);
    return TrainingPackTemplateV2.fromJson(map);
  }

  factory TrainingPackTemplateV2.fromYamlString(String source) =>
      TrainingPackTemplateV2.fromYaml(source);

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

  /// Removes all spots from this template.
  void clear() => spots.clear();

  /// Appends [newSpots] to the existing list of spots.
  void addAll(List<SpotTemplate> newSpots) => spots.addAll(newSpots);

  /// Primary hero position inferred from [positions].
  HeroPosition get heroPos =>
      positions.isNotEmpty ? parseHeroPosition(positions.first) : HeroPosition.unknown;

  /// Hero stack size in big blinds. Backwards compatible alias for [bb].
  int get heroBbStack => bb;

  /// Difficulty level read from [meta] map.
  int get difficultyLevel {
    final diff = meta['difficulty'];
    if (diff is int) return diff;
    if (diff is String) return int.tryParse(diff) ?? 0;
    return 0;
  }

  factory TrainingPackTemplateV2.fromTemplate(
    TrainingPackTemplate template, {
    required TrainingType type,
  }) => TrainingPackTemplateV2(
    id: template.id,
    name: template.name,
    description: template.description,
    goal: template.goal,
    audience: template.meta['audience'] as String?,
    theme: template.meta['theme'] as String?,
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
    requiresTheoryCompleted:
        template.meta['requiresTheoryCompleted'] == true,
    targetStreet: template.targetStreet,
    requiredAccuracy:
        (template.meta['requiredAccuracy'] as num?)?.toDouble(),
    minHands: (template.meta['minHands'] as num?)?.toInt(),
  );
}

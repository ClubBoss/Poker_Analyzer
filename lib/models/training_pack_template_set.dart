import 'package:yaml/yaml.dart';

import '../utils/yaml_utils.dart';
import 'constraint_set.dart';
import 'v2/training_pack_spot.dart';
import 'line_pattern.dart';
import 'postflop_line.dart';
import '../services/training_pack_template_set_validator.dart';

/// Defines a base spot and a list of variation rules that can be expanded
/// into multiple [TrainingPackSpot]s.
class OutputVariant {
  final String key;
  final ConstraintSet constraints;
  final int? seed;

  OutputVariant({required this.key, required this.constraints, this.seed});

  factory OutputVariant.fromJson(String key, Map<String, dynamic> json) {
    final seed = json['seed'];
    final map = Map<String, dynamic>.from(json);
    map.remove('seed');
    return OutputVariant(
      key: key,
      constraints: ConstraintSet.fromJson(map),
      seed: seed is num ? seed.toInt() : null,
    );
  }

  Map<String, dynamic> toJson() => {
        ...constraints.toJson(),
        if (seed != null) 'seed': seed,
      };
}

class TrainingPackTemplateSet {
  /// Shared logic and metadata for all generated spots.
  final TrainingPackSpot baseSpot;

  /// Each variation is represented by a [ConstraintSet] describing overrides
  /// and additional tagging/metadata rules.
  final List<ConstraintSet> variations;

  /// Optional pack-level variants that split generation into multiple outputs.
  ///
  /// Each entry inherits [variations] and may override high-level constraints
  /// such as [ConstraintSet.targetStreet], [ConstraintSet.boardConstraints],
  /// [ConstraintSet.requiredTags], and [ConstraintSet.excludedTags]. A separate
  /// training pack is produced for every variant.
  final Map<String, OutputVariant> outputVariants;

  /// Optional player type variants to apply to generated templates.
  ///
  /// Each entry is written to `spot.meta['playerType']` for the resulting
  /// templates. When empty, the base player type is preserved.
  final List<String> playerTypeVariations;

  /// When `true` an additional template with the hero cards' suits toggled
  /// (suited ↔ offsuit) is produced for every generated spot.
  final bool suitAlternation;

  /// Relative adjustments in big blinds applied to the hero stack depth and the
  /// template's `bb` value. A template is generated for each offset in this
  /// list. When empty, the original stack depth is used.
  final List<int> stackDepthMods;

  /// Optional action line patterns describing multi-street sequences.
  final List<LinePattern> linePatterns;

  /// Optional shorthand postflop action lines applied to the base spot.
  ///
  /// Each entry may include an optional [PostflopLine.weight] controlling
  /// its selection frequency during expansion. When provided, a single line is
  /// chosen based on weighted probability unless [expandAllLines] is `true`.
  /// Each selected line is expanded via [LineGraphEngine.expandLine] to
  /// generate street-specific training spots.
  final List<PostflopLine> postflopLines;

  /// When `true`, all [postflopLines] are expanded regardless of their
  /// [PostflopLine.weight].
  final bool expandAllLines;

  /// Optional deterministic seed used when randomly selecting among
  /// [postflopLines].
  final int? postflopLineSeed;

  /// Optional deterministic seed applied to spot and pack id generation.
  final int? seed;

  /// Optional board texture preset used to filter `postflopLines` expansions.
  ///
  /// When set, the `postflopLines` are only expanded if the base spot's board
  /// matches the named preset via [BoardTexturePresetLibrary.matches].
  final String? boardTexturePreset;

  /// Optional board texture presets that exclude `postflopLines` expansions.
  ///
  /// If any preset in this list matches the base spot's board via
  /// [BoardTexturePresetLibrary.matches], the postflop lines are skipped.
  final List<String> excludeBoardTexturePresets;

  /// Board clusters that must be present on the base board for
  /// `postflopLines` to expand.
  final List<String> requiredBoardClusters;

  /// Board clusters that must not be present on the base board for
  /// `postflopLines` to expand.
  final List<String> excludedBoardClusters;

  const TrainingPackTemplateSet({
    required this.baseSpot,
    List<ConstraintSet>? variations,
    Map<String, OutputVariant>? outputVariants,
    List<String>? playerTypeVariations,
    this.suitAlternation = false,
    List<int>? stackDepthMods,
    List<LinePattern>? linePatterns,
    List<PostflopLine>? postflopLines,
    this.boardTexturePreset,
    List<String>? excludeBoardTexturePresets,
    List<String>? requiredBoardClusters,
    List<String>? excludedBoardClusters,
    this.expandAllLines = false,
    this.postflopLineSeed,
    this.seed,
  })  : variations = variations ?? const [],
        outputVariants = outputVariants ?? const {},
        playerTypeVariations = playerTypeVariations ?? const [],
        stackDepthMods = stackDepthMods ?? const [],
        linePatterns = linePatterns ?? const [],
        postflopLines = postflopLines ?? const [],
        excludeBoardTexturePresets = excludeBoardTexturePresets ?? const [],
        requiredBoardClusters = requiredBoardClusters ?? const [],
        excludedBoardClusters = excludedBoardClusters ?? const [];

  factory TrainingPackTemplateSet.fromJson(
    Map<String, dynamic> json, {
    String source = '',
  }) {
    TrainingPackTemplateSetValidator.validate(json, source: source);
    final baseMap = Map<String, dynamic>.from(
      (json['baseSpot'] ?? json['base'] ?? const {}) as Map,
    );
    final base = TrainingPackSpot.fromJson(baseMap);
    final vars = <ConstraintSet>[
      for (final v in (json['variations'] as List? ?? []))
        ConstraintSet.fromJson(Map<String, dynamic>.from(v as Map)),
    ];
    final outputs = <String, OutputVariant>{};
    final rawOutputs = json['outputVariants'];
    if (rawOutputs is Map) {
      final keys = rawOutputs.keys.map((e) => e.toString()).toList()..sort();
      for (final k in keys) {
        final v = rawOutputs[k];
        if (v is Map) {
          outputs[k] = OutputVariant.fromJson(k, Map<String, dynamic>.from(v));
        }
      }
    } else if (rawOutputs is List) {
      throw FormatException(
        '${source.isNotEmpty ? '$source: ' : ''}'
        'outputVariants must be a map. Migrate to the new schema: '
        'see docs/training_pack_template_schema.md#outputvariants',
      );
    }
    final pTypes = <String>[
      for (final t in (json['playerTypeVariations'] as List? ?? []))
        t.toString(),
    ];
    final suitAlt = json['suitAlternation'] == true;
    final depthMods = <int>[
      for (final m in (json['stackDepthMods'] as List? ?? []))
        (m as num).toInt(),
    ];
    final patterns = <LinePattern>[
      for (final p in (json['linePatterns'] as List? ?? []))
        LinePattern.fromJson(Map<String, dynamic>.from(p as Map)),
    ];

    final postLines = <PostflopLine>[
      for (final l in (json['postflopLines'] as List? ?? []))
        PostflopLine.fromJson(l),
    ];
    final postLine = json['postflopLine'];
    if (postLine != null && postLine.toString().isNotEmpty) {
      postLines.add(PostflopLine.fromJson(postLine));
    }

    final preset = json['boardTexturePreset']?.toString();
    final excluded = <String>[
      for (final p in (json['excludeBoardTexturePresets'] as List? ?? []))
        p.toString(),
    ];
    final requiredClusters = <String>[
      for (final c in (json['requiredBoardClusters'] as List? ?? []))
        c.toString(),
    ];
    final excludedClusters = <String>[
      for (final c in (json['excludedBoardClusters'] as List? ?? []))
        c.toString(),
    ];
    final expandAll = json['expandAllLines'] == true;
    final seed = json['postflopLineSeed'];
    final rootSeed = json['seed'];
    return TrainingPackTemplateSet(
      baseSpot: base,
      variations: vars,
      outputVariants: outputs,
      playerTypeVariations: pTypes,
      suitAlternation: suitAlt,
      stackDepthMods: depthMods,
      linePatterns: patterns,
      postflopLines: postLines,
      boardTexturePreset: preset,
      excludeBoardTexturePresets: excluded,
      requiredBoardClusters: requiredClusters,
      excludedBoardClusters: excludedClusters,
      expandAllLines: expandAll,
      postflopLineSeed: seed is num ? seed.toInt() : null,
      seed: rootSeed is num ? rootSeed.toInt() : null,
    );
  }

  factory TrainingPackTemplateSet.fromYaml(String yaml, {String source = ''}) {
    final map = yamlToDart(loadYaml(yaml)) as Map<String, dynamic>;
    return TrainingPackTemplateSet.fromJson(map, source: source);
  }

  Map<String, dynamic> toJson() => {
        'baseSpot': baseSpot.toJson(),
        if (variations.isNotEmpty)
          'variations': [for (final v in variations) v.toJson()],
        if (outputVariants.isNotEmpty)
          'outputVariants': {
            for (final k in outputVariants.keys.toList()..sort())
              k: outputVariants[k]!.toJson(),
          },
        if (playerTypeVariations.isNotEmpty)
          'playerTypeVariations': playerTypeVariations,
        if (suitAlternation) 'suitAlternation': true,
        if (stackDepthMods.isNotEmpty) 'stackDepthMods': stackDepthMods,
        if (linePatterns.isNotEmpty)
          'linePatterns': [for (final p in linePatterns) p.toJson()],
        if (postflopLines.length == 1 && postflopLines.first.weight == 1)
          'postflopLine': postflopLines.first.line
        else if (postflopLines.isNotEmpty)
          'postflopLines': [
            for (final l in postflopLines) l.weight == 1 ? l.line : l.toJson(),
          ],
        if (boardTexturePreset != null && boardTexturePreset!.isNotEmpty)
          'boardTexturePreset': boardTexturePreset,
        if (excludeBoardTexturePresets.isNotEmpty)
          'excludeBoardTexturePresets': excludeBoardTexturePresets,
        if (requiredBoardClusters.isNotEmpty)
          'requiredBoardClusters': requiredBoardClusters,
        if (excludedBoardClusters.isNotEmpty)
          'excludedBoardClusters': excludedBoardClusters,
        if (expandAllLines) 'expandAllLines': true,
        if (postflopLineSeed != null) 'postflopLineSeed': postflopLineSeed,
        if (seed != null) 'seed': seed,
      };
}

import 'package:yaml/yaml.dart';

import '../utils/yaml_utils.dart';
import 'constraint_set.dart';
import 'v2/training_pack_spot.dart';

/// Defines a base spot and a list of variation rules that can be expanded
/// into multiple [TrainingPackSpot]s.
class TrainingPackTemplateSet {
  /// Shared logic and metadata for all generated spots.
  final TrainingPackSpot baseSpot;

  /// Each variation is represented by a [ConstraintSet] describing overrides
  /// and additional tagging/metadata rules.
  final List<ConstraintSet> variations;

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

  const TrainingPackTemplateSet({
    required this.baseSpot,
    List<ConstraintSet>? variations,
    List<String>? playerTypeVariations,
    this.suitAlternation = false,
    List<int>? stackDepthMods,
  })  : variations = variations ?? const [],
        playerTypeVariations = playerTypeVariations ?? const [],
        stackDepthMods = stackDepthMods ?? const [];

  factory TrainingPackTemplateSet.fromJson(Map<String, dynamic> json) {
    final baseMap = Map<String, dynamic>.from(
      (json['baseSpot'] ?? json['base'] ?? const {}) as Map,
    );
    final base = TrainingPackSpot.fromJson(baseMap);
    final vars = <ConstraintSet>[
      for (final v in (json['variations'] as List? ?? []))
        ConstraintSet.fromJson(Map<String, dynamic>.from(v as Map)),
    ];
    final pTypes = <String>[
      for (final t in (json['playerTypeVariations'] as List? ?? []))
        t.toString(),
    ];
    final suitAlt = json['suitAlternation'] == true;
    final depthMods = <int>[
      for (final m in (json['stackDepthMods'] as List? ?? []))
        (m as num).toInt(),
    ];
    return TrainingPackTemplateSet(
      baseSpot: base,
      variations: vars,
      playerTypeVariations: pTypes,
      suitAlternation: suitAlt,
      stackDepthMods: depthMods,
    );
  }

  factory TrainingPackTemplateSet.fromYaml(String yaml) {
    final map = yamlToDart(loadYaml(yaml)) as Map<String, dynamic>;
    return TrainingPackTemplateSet.fromJson(map);
  }

  Map<String, dynamic> toJson() => {
        'baseSpot': baseSpot.toJson(),
        if (variations.isNotEmpty)
          'variations': [for (final v in variations) v.toJson()],
        if (playerTypeVariations.isNotEmpty)
          'playerTypeVariations': playerTypeVariations,
        if (suitAlternation) 'suitAlternation': true,
        if (stackDepthMods.isNotEmpty) 'stackDepthMods': stackDepthMods,
      };
}


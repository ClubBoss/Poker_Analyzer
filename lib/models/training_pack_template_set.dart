import 'package:yaml/yaml.dart';

import '../utils/yaml_utils.dart';
import 'constraint_set.dart';
import 'v2/training_pack_spot.dart';
import 'line_pattern.dart';

/// Defines a base spot and a list of variation rules that can be expanded
/// into multiple [TrainingPackSpot]s.
class TrainingPackTemplateSet {
  /// Shared logic and metadata for all generated spots.
  final TrainingPackSpot baseSpot;

  /// Each variation is represented by a [ConstraintSet] describing overrides
  /// and additional tagging/metadata rules.
  final List<ConstraintSet> variations;

  /// Optional structured action sequences to generate additional line data.
  final List<LinePattern> linePatterns;

  const TrainingPackTemplateSet({
    required this.baseSpot,
    List<ConstraintSet>? variations,
    List<LinePattern>? linePatterns,
  }) : variations = variations ?? const [],
       linePatterns = linePatterns ?? const [];

  factory TrainingPackTemplateSet.fromJson(Map<String, dynamic> json) {
    final baseMap = Map<String, dynamic>.from(
      (json['baseSpot'] ?? json['base'] ?? const {}) as Map,
    );
    final base = TrainingPackSpot.fromJson(baseMap);
    final vars = <ConstraintSet>[
      for (final v in (json['variations'] as List? ?? []))
        ConstraintSet.fromJson(Map<String, dynamic>.from(v as Map)),
    ];
    final lines = <LinePattern>[
      for (final p in (json['linePatterns'] as List? ?? []))
        LinePattern.fromJson(Map<String, dynamic>.from(p as Map)),
    ];
    return TrainingPackTemplateSet(
      baseSpot: base,
      variations: vars,
      linePatterns: lines,
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
    if (linePatterns.isNotEmpty)
      'linePatterns': [for (final p in linePatterns) p.toJson()],
  };
}

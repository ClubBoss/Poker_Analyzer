import 'package:yaml/yaml.dart';

import '../../utils/yaml_utils.dart';
import '../constraint_set.dart';
import 'training_pack_template_v2.dart';

/// Defines a template with variant parameters that can be expanded into
/// multiple [TrainingPackTemplateV2] instances.
class TrainingPackTemplateSet {
  TrainingPackTemplateV2 template;

  /// Mustache-style variants for legacy expansion.
  List<Map<String, dynamic>> variants;

  /// Named constraint-based entries producing multiple packs from the same
  /// template.
  List<TemplateSetEntry> entries;

  TrainingPackTemplateSet({
    required this.template,
    List<Map<String, dynamic>>? variants,
    List<TemplateSetEntry>? entries,
  }) : variants = variants ?? [],
       entries = entries ?? [];

  factory TrainingPackTemplateSet.fromJson(Map<String, dynamic> json) {
    // Determine base template map. If a nested `template` map is provided use
    // it, otherwise treat the whole object minus helper keys as the template.
    final map = Map<String, dynamic>.from(json);
    Map<String, dynamic> tplMap;
    if (map['template'] is Map) {
      tplMap = Map<String, dynamic>.from(map['template']);
    } else {
      tplMap = Map<String, dynamic>.from(map);
      tplMap.remove('variants');
      tplMap.remove('templateSet');
    }

    return TrainingPackTemplateSet(
      template: TrainingPackTemplateV2.fromJson(tplMap),
      variants: [
        for (final v in (json['variants'] as List? ?? []))
          Map<String, dynamic>.from(v as Map),
      ],
      entries: [
        for (final e in (json['templateSet'] as List? ?? []))
          TemplateSetEntry.fromJson(Map<String, dynamic>.from(e as Map)),
      ],
    );
  }

  factory TrainingPackTemplateSet.fromYaml(String yaml) {
    final map = yamlToDart(loadYaml(yaml)) as Map<String, dynamic>;
    return TrainingPackTemplateSet.fromJson(map);
  }
}

/// Configuration for a single output pack within a [TrainingPackTemplateSet].
class TemplateSetEntry {
  final String name;
  final ConstraintSet constraints;

  TemplateSetEntry({required this.name, required this.constraints});

  factory TemplateSetEntry.fromJson(Map<String, dynamic> json) {
    final c = Map<String, dynamic>.from(json['constraints'] ?? {});
    return TemplateSetEntry(
      name: json['name']?.toString() ?? '',
      constraints: ConstraintSet(
        boardTags: [
          for (final t in (c['boardTags'] as List? ?? [])) t.toString(),
        ],
        positions: [
          for (final p in (c['positions'] as List? ?? [])) p.toString(),
        ],
        handGroup: [
          for (final g in (c['handGroup'] as List? ?? [])) g.toString(),
        ],
        villainActions: [
          for (final a in (c['villainActions'] as List? ?? [])) a.toString(),
        ],
        targetStreet: c['targetStreet']?.toString(),
      ),
    );
  }
}

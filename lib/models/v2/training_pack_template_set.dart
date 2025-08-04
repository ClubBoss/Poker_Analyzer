import 'package:yaml/yaml.dart';

import '../../utils/yaml_utils.dart';
import '../constraint_set.dart';
import '../line_pattern.dart';
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

  /// Optional action line patterns describing multi-street sequences.
  List<LinePattern> linePatterns;

  TrainingPackTemplateSet({
    required this.template,
    List<Map<String, dynamic>>? variants,
    List<TemplateSetEntry>? entries,
    List<LinePattern>? linePatterns,
  }) : variants = variants ?? [],
       entries = entries ?? [],
       linePatterns = linePatterns ?? [];

  factory TrainingPackTemplateSet.fromJson(Map<String, dynamic> json) {
    // Support multiple input structures:
    // 1) Legacy format with `template` + `variants` or `templateSet`.
    // 2) Simplified format with `base` + `variations` fields.
    final map = Map<String, dynamic>.from(json);
    final patterns = <LinePattern>[
      for (final p in (map['linePatterns'] as List? ?? []))
        LinePattern.fromJson(Map<String, dynamic>.from(p as Map)),
    ];

    // New `base` + `variations` structure.
    if (map['base'] is Map && map['variations'] is List) {
      final baseMap = Map<String, dynamic>.from(map['base'] as Map);
      // Allow `title` as an alias for `name`.
      if (baseMap.containsKey('title') && !baseMap.containsKey('name')) {
        baseMap['name'] = baseMap.remove('title');
      }
      final templateId = map['templateId']?.toString();
      if (templateId != null && templateId.isNotEmpty) {
        baseMap['id'] ??= templateId;
      }
      final tpl = TrainingPackTemplateV2.fromJson(baseMap);
      final baseName = tpl.name;
      final entries = <TemplateSetEntry>[];
      final variations = map['variations'] as List;
      for (var i = 0; i < variations.length; i++) {
        final v = Map<String, dynamic>.from(variations[i] as Map);
        final tags = <String>[
          for (final t in (v['tags'] as List? ?? [])) t.toString(),
        ];
        final acts = <String>[
          for (final a in (v['villainActions'] as List? ?? [])) a.toString(),
        ];
        final suffix = v['titleSuffix']?.toString() ??
            (tags.isNotEmpty ? tags.join(' ') : 'var${i + 1}');
        final name = suffix.isNotEmpty ? '$baseName - $suffix' : baseName;
        entries.add(
          TemplateSetEntry(
            name: name,
            tags: tags,
            constraints: ConstraintSet(villainActions: acts),
          ),
        );
      }
      return TrainingPackTemplateSet(
        template: tpl,
        entries: entries,
        linePatterns: patterns,
      );
    }

    // Legacy structures.
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
      linePatterns: patterns,
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
  final List<String> tags;

  TemplateSetEntry({required this.name, required this.constraints, List<String>? tags})
      : tags = tags ?? [];

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
      tags: [
        for (final t in (json['tags'] as List? ?? [])) t.toString(),
      ],
    );
  }
}

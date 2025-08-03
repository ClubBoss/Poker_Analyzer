import 'package:yaml/yaml.dart';

import '../../utils/yaml_utils.dart';
import 'training_pack_template_v2.dart';

/// Defines a template with variant parameters that can be expanded into
/// multiple [TrainingPackTemplateV2] instances.
class TrainingPackTemplateSet {
  TrainingPackTemplateV2 template;
  List<Map<String, dynamic>> variants;

  TrainingPackTemplateSet({
    required this.template,
    List<Map<String, dynamic>>? variants,
  }) : variants = variants ?? [];

  factory TrainingPackTemplateSet.fromJson(Map<String, dynamic> json) =>
      TrainingPackTemplateSet(
        template: TrainingPackTemplateV2.fromJson(
          Map<String, dynamic>.from(json['template'] ?? {}),
        ),
        variants: [
          for (final v in (json['variants'] as List? ?? []))
            Map<String, dynamic>.from(v as Map),
        ],
      );

  factory TrainingPackTemplateSet.fromYaml(String yaml) {
    final map = yamlToDart(loadYaml(yaml)) as Map<String, dynamic>;
    return TrainingPackTemplateSet.fromJson(map);
  }
}

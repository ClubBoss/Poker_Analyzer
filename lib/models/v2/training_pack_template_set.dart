import 'package:yaml/yaml.dart';

import '../../utils/yaml_utils.dart';
import 'training_pack_template_v2.dart';

class TrainingPackTemplateSet {
  String id;
  String name;
  TrainingPackTemplateV2 baseTemplate;
  List<Map<String, dynamic>> dynamicParamVariants;

  TrainingPackTemplateSet({
    required this.id,
    required this.name,
    required this.baseTemplate,
    List<Map<String, dynamic>>? dynamicParamVariants,
  }) : dynamicParamVariants = dynamicParamVariants ?? [];

  List<TrainingPackTemplateV2> generateAllPacks() {
    final packs = <TrainingPackTemplateV2>[];
    for (final variant in dynamicParamVariants) {
      final baseMap = Map<String, dynamic>.from(baseTemplate.toJson());
      final meta = Map<String, dynamic>.from(baseMap['meta'] ?? {});
      final dyn = Map<String, dynamic>.from(variant);
      final id = dyn.remove('id');
      final name = dyn.remove('name');
      meta['dynamicParams'] = dyn;
      baseMap['meta'] = meta;
      if (id != null) baseMap['id'] = id.toString();
      if (name != null) baseMap['name'] = name.toString();
      packs.add(TrainingPackTemplateV2.fromJson(baseMap));
    }
    return packs;
  }

  factory TrainingPackTemplateSet.fromJson(Map<String, dynamic> json) =>
      TrainingPackTemplateSet(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        baseTemplate: TrainingPackTemplateV2.fromJson(
          Map<String, dynamic>.from(json['baseTemplate'] ?? {}),
        ),
        dynamicParamVariants: [
          for (final v in (json['dynamicParamVariants'] as List? ?? []))
            Map<String, dynamic>.from(v as Map),
        ],
      );

  factory TrainingPackTemplateSet.fromYaml(String yaml) {
    final map = yamlToDart(loadYaml(yaml)) as Map<String, dynamic>;
    final root = map['templateSet'] is Map
        ? Map<String, dynamic>.from(map['templateSet'])
        : map;
    return TrainingPackTemplateSet.fromJson(root);
  }

  static List<TrainingPackTemplateV2> generateAllFromYaml(String yaml) {
    final set = TrainingPackTemplateSet.fromYaml(yaml);
    return set.generateAllPacks();
  }
}

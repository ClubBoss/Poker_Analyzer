import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

import '../../models/v2/training_pack_template_v2.dart';
import '../../models/v2/training_pack_template_set.dart';
import '../../services/training_pack_template_set_generator.dart';
import '../../services/theory_yaml_safe_reader.dart';
import '../../../utils/yaml_utils.dart';

class YamlReader {
  const YamlReader();

  Map<String, dynamic> read(String source) {
    final doc = loadYaml(source);
    return yamlToDart(doc) as Map<String, dynamic>;
  }

  /// Loads a training pack template from [path]. The path can point to an asset
  /// (starting with `assets/`) or to a file on disk.
  Future<TrainingPackTemplateV2> loadTemplate(String path) async {
    if (path.startsWith('assets/')) {
      final source = await rootBundle.loadString(path);
      return TrainingPackTemplateV2.fromYamlAuto(source);
    }
    final map = await TheoryYamlSafeReader().read(
      path: path,
      schema: 'TemplateSet',
    );
    return TrainingPackTemplateV2.fromJson(map);
  }

  /// Loads all templates defined in [path]. The file may contain either a
  /// single template or a template set with `template` and `variants` fields.
  /// When a set is provided, it expands into multiple [TrainingPackTemplateV2]
  /// instances using the variant values.
  Future<List<TrainingPackTemplateV2>> loadTemplates(String path) async {
    if (path.startsWith('assets/')) {
      final source = await rootBundle.loadString(path);
      final map = read(source);
      if ((map['template'] is Map && map['variants'] is List) ||
          map['templateSet'] is List ||
          (map['base'] is Map && map['variations'] is List)) {
        final set = TrainingPackTemplateSet.fromJson(map);
        return const TrainingPackTemplateSetGenerator().generate(set);
      }
      final tpl = TrainingPackTemplateV2.fromJson(
        Map<String, dynamic>.from(map),
      );
      return [tpl];
    }
    final map = await TheoryYamlSafeReader().read(
      path: path,
      schema: 'TemplateSet',
    );
    if ((map['template'] is Map && map['variants'] is List) ||
        map['templateSet'] is List ||
        (map['base'] is Map && map['variations'] is List)) {
      final set = TrainingPackTemplateSet.fromJson(map);
      return const TrainingPackTemplateSetGenerator().generate(set);
    }
    final tpl = TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(map));
    return [tpl];
  }
}

import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

import '../../models/v2/training_pack_template_v2.dart';
import '../../models/v2/training_pack_template_set.dart';
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
    final source = path.startsWith('assets/')
        ? await rootBundle.loadString(path)
        : await File(path).readAsString();
    return TrainingPackTemplateV2.fromYamlAuto(source);
  }

  /// Loads all templates defined in [path]. The file may contain either a
  /// single template or a `templateSet` definition. When a set is provided, it
  /// expands into multiple [TrainingPackTemplateV2] instances using the
  /// `dynamicParamVariants`.
  Future<List<TrainingPackTemplateV2>> loadTemplates(String path) async {
    final source = path.startsWith('assets/')
        ? await rootBundle.loadString(path)
        : await File(path).readAsString();
    final map = read(source);
    if (map['templateSet'] is Map) {
      final set = TrainingPackTemplateSet.fromJson(
        Map<String, dynamic>.from(map['templateSet'] as Map),
      );
      return set.generateAllPacks();
    }
    final tpl = TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(map));
    return [tpl];
  }
}

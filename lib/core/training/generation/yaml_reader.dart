import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

import '../../models/v2/training_pack_template_v2.dart';
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
}

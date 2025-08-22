import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:json2yaml/json2yaml.dart';
import 'package:path/path.dart' as p;

import '../models/v2/training_pack_template_v2.dart';
import '../core/training/engine/training_type_engine.dart';

/// Exports theory packs from a library into YAML files.
class BoosterTheoryExportEngine {
  BoosterTheoryExportEngine();

  /// Writes every theory pack from [library] into [dir].
  ///
  /// Returns paths of the exported files.
  Future<List<String>> export(
    List<TrainingPackTemplateV2> library, {
    String dir = 'yaml_out/theory',
  }) async {
    if (!kDebugMode) return [];
    final directory = Directory(dir);
    await directory.create(recursive: true);
    final paths = <String>[];
    for (final pack in library) {
      if (pack.trainingType != TrainingType.theory) continue;
      final yaml = _encodeYaml(pack.toJson());
      final file = File(p.join(directory.path, '${pack.id}.yaml'));
      await file.writeAsString('$yaml\n');
      paths.add(file.path);
    }
    return paths;
  }

  String _encodeYaml(Map<String, dynamic> map) =>
      json2yaml(map, yamlStyle: YamlStyle.pubspecYaml);
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

import '../models/learning_path_template_v2.dart';

/// Loads [LearningPathTemplateV2] definitions from YAML files under
/// `assets/learning_paths/`.
class LearningPathLoader {
  const LearningPathLoader();

  /// Loads a path by [pathId]. The file name should match the id.
  Future<LearningPathTemplateV2> load(String pathId) async {
    final raw = await rootBundle.loadString(
      'assets/learning_paths/' + pathId + '.yaml',
    );
    final yaml = loadYaml(raw);
    if (yaml is Map) {
      return LearningPathTemplateV2.fromYaml(Map.from(yaml));
    }
    throw Exception('Invalid learning path yaml for id: ' + pathId);
  }

  /// Loads all path templates available in the asset manifest.
  Future<List<LearningPathTemplateV2>> loadAll() async {
    final manifestRaw = await rootBundle.loadString('AssetManifest.json');
    final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;
    final paths =
        manifest.keys
            .where(
              (e) =>
                  e.startsWith('assets/learning_paths/') && e.endsWith('.yaml'),
            )
            .toList()
          ..sort();
    final list = <LearningPathTemplateV2>[];
    for (final p in paths) {
      try {
        final raw = await rootBundle.loadString(p);
        final yaml = loadYaml(raw);
        if (yaml is Map) {
          list.add(LearningPathTemplateV2.fromYaml(Map.from(yaml)));
        }
      } catch (_) {}
    }
    return list;
  }

  /// Loads a path from [file] on disk. Used by tests or tools.
  Future<LearningPathTemplateV2> loadFromFile(File file) async {
    final raw = await file.readAsString();
    final yaml = loadYaml(raw);
    if (yaml is Map) {
      return LearningPathTemplateV2.fromYaml(Map.from(yaml));
    }
    throw Exception('Invalid learning path yaml in ' + file.path);
  }
}

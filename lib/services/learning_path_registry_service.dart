import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

import '../models/learning_path_template_v2.dart';

class LearningPathRegistryService {
  LearningPathRegistryService._();

  static final instance = LearningPathRegistryService._();

  final List<LearningPathTemplateV2> _templates = [];

  /// Loads all learning path templates from [assets/learning_paths].
  /// Subsequent calls return cached data.
  Future<List<LearningPathTemplateV2>> loadAll() async {
    if (_templates.isNotEmpty) return _templates;
    try {
      final manifestRaw = await rootBundle.loadString('AssetManifest.json');
      final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;
      final paths = manifest.keys
          .where((e) =>
              e.startsWith('assets/learning_paths/') && e.endsWith('.yaml'))
          .toList()
        ..sort();
      for (final p in paths) {
        try {
          final raw = await rootBundle.loadString(p);
          final yaml = loadYaml(raw);
          if (yaml is Map) {
            _templates.add(
              LearningPathTemplateV2.fromYaml(Map.from(yaml)),
            );
          }
        } catch (_) {}
      }
    } catch (_) {}
    return _templates;
  }

  /// Returns template with the given [id] if loaded.
  LearningPathTemplateV2? findById(String id) =>
      _templates.firstWhereOrNull((e) => e.id == id);

  /// Returns a sorted list of all unique tags across loaded templates.
  List<String> listTags() {
    final set = <String>{};
    for (final t in _templates) {
      for (final tag in t.tags) {
        final trimmed = tag.trim();
        if (trimmed.isNotEmpty) set.add(trimmed);
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  /// Returns templates that contain [tag].
  List<LearningPathTemplateV2> filterByTag(String tag) => [
        for (final t in _templates)
          if (t.tags.contains(tag)) t,
      ];
}

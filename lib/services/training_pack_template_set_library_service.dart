import 'package:flutter/services.dart' show rootBundle;

import '../asset_manifest.dart';
import '../models/training_pack_template_set.dart';

/// Loads training pack template sets from asset YAML files.
class TrainingPackTemplateSetLibraryService {
  TrainingPackTemplateSetLibraryService._();
  static final TrainingPackTemplateSetLibraryService instance =
      TrainingPackTemplateSetLibraryService._();

  static const List<String> _dirs = ['assets/templates/postflop_sets/'];

  final List<TrainingPackTemplateSet> _sets = [];

  List<TrainingPackTemplateSet> get all => List.unmodifiable(_sets);

  Future<void> loadAll() async {
    if (_sets.isNotEmpty) return;
    await reload();
  }

  Future<void> reload() async {
    _sets.clear();
    final manifest = await AssetManifest.instance;
    final paths = manifest.keys
        .where((p) => _dirs.any((d) => p.startsWith(d)) && p.endsWith('.yaml'))
        .toList();
    for (final path in paths) {
      try {
        final raw = await rootBundle.loadString(path);
        _sets.add(TrainingPackTemplateSet.fromYaml(raw));
      } catch (_) {}
    }
  }
}

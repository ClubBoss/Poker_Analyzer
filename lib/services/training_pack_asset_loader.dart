import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

import '../models/v2/training_pack_template.dart';
import '../helpers/training_pack_validator.dart';

class TrainingPackAssetLoader {
  TrainingPackAssetLoader._();
  static final instance = TrainingPackAssetLoader._();

  final List<TrainingPackTemplate> _packs = [];

  Future<void> loadAll() async {
    _packs.clear();
    final manifestRaw = await rootBundle.loadString('AssetManifest.json');
    final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;
    final paths = manifest.keys.where(
      (e) => e.startsWith('assets/packs/') && e.endsWith('.yaml'),
    );
    for (final p in paths) {
      try {
        final str = await rootBundle.loadString(p);
        final map = jsonDecode(jsonEncode(loadYaml(str))) as Map<String, dynamic>;
        final tpl = TrainingPackTemplate.fromJson(map);
        final issues = validateTrainingPackTemplate(tpl);
        if (issues.isEmpty) _packs.add(tpl);
      } catch (_) {}
    }
  }

  List<TrainingPackTemplate> getAll() => List.unmodifiable(_packs);
}

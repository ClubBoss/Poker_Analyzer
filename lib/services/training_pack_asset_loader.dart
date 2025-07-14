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
    final paths = manifest.keys.where((e) {
      final ok = e.startsWith('assets/packs/') ||
          e.startsWith('assets/training_templates/');
      return ok && (e.endsWith('.yaml') || e.endsWith('.json'));
    });
    for (final p in paths) {
      try {
        final str = await rootBundle.loadString(p);
        Map<String, dynamic> map;
        if (p.endsWith('.yaml')) {
          map = jsonDecode(jsonEncode(loadYaml(str))) as Map<String, dynamic>;
        } else {
          final json = jsonDecode(str);
          if (json is! Map<String, dynamic>) continue;
          map = Map<String, dynamic>.from(json);
        }
        final tpl = TrainingPackTemplate.fromJson(map);
        final issues = validateTrainingPackTemplate(tpl);
        if (issues.isEmpty) _packs.add(tpl);
      } catch (_) {}
    }
  }

  List<TrainingPackTemplate> getAll() => List.unmodifiable(_packs);
}

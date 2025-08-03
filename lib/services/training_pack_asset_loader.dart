import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

import '../models/v2/training_pack_template.dart';
import '../models/v2/hero_position.dart';
import '../helpers/training_pack_validator.dart';
import 'package:collection/collection.dart';

class TrainingPackAssetLoader {
  TrainingPackAssetLoader._();
  static final instance = TrainingPackAssetLoader._();

  final List<TrainingPackTemplate> _packs = [];

  bool _validMeta(TrainingPackTemplate t, Set<String> ids) {
    if (t.spots.isEmpty) return false;
    if (t.spotCount != t.spots.length) return false;
    if (t.heroPos == HeroPosition.unknown) return false;
    if (t.playerStacksBb.isEmpty || t.playerStacksBb.any((v) => v <= 0)) {
      return false;
    }
    if (t.name.trim().isEmpty) return false;
    if (ids.contains(t.id)) return false;
    ids.add(t.id);
    return true;
  }

  Future<void> loadAll() async {
    _packs.clear();
    final ids = <String>{};
    final manifestRaw = await rootBundle.loadString('AssetManifest.json');
    final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;
    final List<String> paths = manifest.keys.where((e) {
      final ok =
          e.startsWith('assets/packs/') ||
          e.startsWith('assets/training_templates/') ||
          e.startsWith('assets/templates/');
      return ok && (e.endsWith('.yaml') || e.endsWith('.json'));
    }).toList();
    const libPath = 'assets/training_packs/training_pack_library.json';
    if (manifest.containsKey(libPath)) paths.add(libPath);
    for (final p in paths) {
      try {
        final str = await rootBundle.loadString(p);
        if (p.endsWith('training_pack_library.json')) {
          final list = jsonDecode(str);
          if (list is List) {
            for (final item in list) {
              if (item is Map) {
                final tpl = TrainingPackTemplate.fromJson(
                  Map<String, dynamic>.from(item),
                );
                tpl.tags = [
                  for (final t in tpl.tags)
                    if (t.trim().isNotEmpty) t,
                ];
                if (!_validMeta(tpl, ids)) continue;
                final issues = validateTrainingPackTemplate(tpl);
                if (issues.isEmpty) _packs.add(tpl);
              }
            }
          }
          continue;
        }
        Map<String, dynamic> map;
        if (p.endsWith('.yaml')) {
          map = jsonDecode(jsonEncode(loadYaml(str))) as Map<String, dynamic>;
        } else {
          final json = jsonDecode(str);
          if (json is! Map<String, dynamic>) continue;
          map = Map<String, dynamic>.from(json);
        }
        final tpl = TrainingPackTemplate.fromJson(map);
        tpl.tags = [
          for (final t in tpl.tags)
            if (t.trim().isNotEmpty) t,
        ];
        if (!_validMeta(tpl, ids)) continue;
        final issues = validateTrainingPackTemplate(tpl);
        if (issues.isEmpty) _packs.add(tpl);
      } catch (_) {}
    }
  }

  List<TrainingPackTemplate> getAll() => List.unmodifiable(_packs);

  TrainingPackTemplate? getById(String id) =>
      _packs.firstWhereOrNull((p) => p.id == id);
}

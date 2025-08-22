import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';

class PackLibraryConflictScanner {
  PackLibraryConflictScanner();

  Future<List<(String, String)>> scanConflicts({
    String path = 'training_packs/library',
  }) async {
    if (!kDebugMode) return [];
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$path');
    if (!dir.existsSync()) return [];
    const reader = YamlReader();
    final idMap = <String, String>{};
    final duplicates = <String>[];
    final invalid = <String>[];
    final evGroups = <String, List<(String, double)>>{};
    final icmGroups = <String, List<(String, double)>>{};
    for (final f
        in dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((e) => e.path.toLowerCase().endsWith('.yaml'))) {
      try {
        final yaml = await f.readAsString();
        final map = reader.read(yaml);
        final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
        if (idMap.containsKey(tpl.id)) {
          duplicates.add(f.path);
        } else {
          idMap[tpl.id] = f.path;
        }
        final meta = tpl.meta;
        if (meta.isEmpty) invalid.add(f.path);
        final aud = tpl.audience ?? 'Unknown';
        final ev =
            (map['evScore'] as num?)?.toDouble() ??
            (meta['evScore'] as num?)?.toDouble();
        final icm =
            (map['icmScore'] as num?)?.toDouble() ??
            (meta['icmScore'] as num?)?.toDouble();
        for (final t in tpl.tags) {
          final key = '$aud|$t';
          if (ev != null) {
            evGroups.putIfAbsent(key, () => []).add((f.path, ev));
          }
          if (icm != null) {
            icmGroups.putIfAbsent(key, () => []).add((f.path, icm));
          }
        }
      } catch (_) {
        invalid.add(f.path);
      }
    }
    final conflicts = <(String, String)>[
      for (final p in duplicates) (p, 'duplicate_id'),
      for (final p in invalid) (p, 'invalid_meta'),
    ];
    void check(Map<String, List<(String, double)>> groups, String type) {
      for (final e in groups.entries) {
        final v = e.value;
        if (v.length < 2) continue;
        var minVal = v.first.$2;
        var maxVal = v.first.$2;
        for (final x in v) {
          minVal = min(minVal, x.$2);
          maxVal = max(maxVal, x.$2);
        }
        final avg = (minVal.abs() + maxVal.abs()) / 2;
        if (avg == 0) continue;
        if ((maxVal - minVal).abs() / avg > 0.25) {
          conflicts.addAll([for (final x in v) (x.$1, type)]);
        }
      }
    }

    check(evGroups, 'ev_dispersion');
    check(icmGroups, 'icm_dispersion');
    return conflicts;
  }
}

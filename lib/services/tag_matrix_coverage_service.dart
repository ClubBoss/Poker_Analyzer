import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/training/engine/training_type_engine.dart';
import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'matrix_tag_config_service.dart';

class TagMatrixCellData {
  int count;
  final List<String> packs;
  TagMatrixCellData(this.count, this.packs);
}

class TagMatrixCoverageResult {
  final List<MatrixAxis> axes;
  final Map<String, Map<String, TagMatrixCellData>> cells;
  final int max;
  const TagMatrixCoverageResult({
    required this.axes,
    required this.cells,
    required this.max,
  });
}

class TagMatrixCoverageService {
  const TagMatrixCoverageService();

  Future<TagMatrixCoverageResult> load({
    TrainingType? type,
    bool starter = false,
  }) async {
    final res = await compute(_coverageTask, {
      'type': type?.name,
      'starter': starter,
    });
    final axes = [
      for (final a in res['axes'] as List)
        MatrixAxis.fromJson(Map<String, dynamic>.from(a))
    ];
    final data = <String, Map<String, TagMatrixCellData>>{};
    int max = 1;
    final cells = res['cells'] as Map;
    cells.forEach((k, v) {
      final inner = <String, TagMatrixCellData>{};
      (v as Map).forEach((kk, vv) {
        final m = vv as Map;
        final d = TagMatrixCellData(
            m['count'] as int, [for (final p in m['packs']) p.toString()]);
        if (d.count > max) max = d.count;
        inner[kk as String] = d;
      });
      data[k as String] = inner;
    });
    if (max <= 0) max = 1;
    return TagMatrixCoverageResult(axes: axes, cells: data, max: max);
  }
}

Future<Map<String, dynamic>> _coverageTask(Map args) async {
  final axes = await const MatrixTagConfigService().load();
  final xVals = axes[0].values;
  final yVals = axes.length > 1 ? axes[1].values : <String>[];
  final cells = <String, Map<String, Map<String, dynamic>>>{};
  for (final x in xVals) {
    cells[x] = {for (final y in yVals) y: {'count': 0, 'packs': <String>[]}};
  }
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}/training_packs/library');
  if (dir.existsSync()) {
    const reader = YamlReader();
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'));
    for (final f in files) {
      try {
        final map = reader.read(await f.readAsString());
        final tpl = TrainingPackTemplateV2.fromJson(map);
        final type = args['type'] as String?;
        if (type != null && type.isNotEmpty && tpl.trainingType.name != type) {
          continue;
        }
        if (args['starter'] == true &&
            !tpl.tags.any((t) => t.toLowerCase().contains('starter'))) {
          continue;
        }
        final rel = p.relative(f.path, from: dir.path);
        final bb = tpl.bb;
        final stack = bb >= 21
            ? '21+'
            : bb >= 13
                ? '13-20'
                : bb >= 8
                    ? '8-12'
                    : bb >= 5
                        ? '5-7'
                        : '<5';
        final posList = tpl.positions.isNotEmpty
            ? tpl.positions
            : [
                for (final t in tpl.tags)
                  if (t.startsWith('position:')) t.substring(9)
              ];
        for (final p0 in posList) {
          final p1 = p0.toUpperCase();
          final map = cells[p1];
          if (map == null) continue;
          final cell = map[stack];
          if (cell == null) continue;
          cell['count'] = (cell['count'] as int) + 1;
          (cell['packs'] as List).add(rel);
        }
      } catch (_) {}
    }
  }
  return {
    'axes': [for (final a in axes) a.toJson()],
    'cells': cells,
  };
}

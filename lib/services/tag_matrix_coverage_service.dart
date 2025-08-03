import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/training/engine/training_type_engine.dart';
import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'matrix_tag_config_service.dart';

class TagMatrixAxes {
  final List<MatrixAxis> axes;

  const TagMatrixAxes(this.axes);

  int get length => axes.length;

  MatrixAxis operator [](int index) => axes[index];

  factory TagMatrixAxes.fromJson(List<dynamic> list) =>
      TagMatrixAxes([
        for (final a in list)
          MatrixAxis.fromJson(Map<String, dynamic>.from(a as Map))
      ]);

  List<Map<String, dynamic>> toJson() => [for (final a in axes) a.toJson()];
}

class TagMatrixCell {
  int count;
  final List<String> packs;

  TagMatrixCell(this.count, this.packs);

  factory TagMatrixCell.fromJson(Map<String, dynamic> json) => TagMatrixCell(
        json['count'] as int,
        [for (final p in json['packs']) p.toString()],
      );

  Map<String, dynamic> toJson() => {'count': count, 'packs': packs};
}

class TagMatrixResult {
  final TagMatrixAxes axes;
  final Map<String, Map<String, TagMatrixCell>> cells;
  final int max;

  const TagMatrixResult({
    required this.axes,
    required this.cells,
    required this.max,
  });

  factory TagMatrixResult.fromJson(Map<String, dynamic> json) {
    final axes = TagMatrixAxes.fromJson(json['axes'] as List);
    final cells = <String, Map<String, TagMatrixCell>>{};
    int max = 1;
    final raw = json['cells'] as Map;
    raw.forEach((k, v) {
      final inner = <String, TagMatrixCell>{};
      (v as Map).forEach((kk, vv) {
        final cell =
            TagMatrixCell.fromJson(Map<String, dynamic>.from(vv as Map));
        if (cell.count > max) max = cell.count;
        inner[kk as String] = cell;
      });
      cells[k as String] = inner;
    });
    if (max <= 0) max = 1;
    return TagMatrixResult(axes: axes, cells: cells, max: max);
  }
}

class TagMatrixCoverageService {
  const TagMatrixCoverageService();

  Future<TagMatrixResult> load({
    TrainingType? type,
    bool starter = false,
  }) async {
    final res = await compute(_coverageTask, {
      'type': type?.name,
      'starter': starter,
    });
    return TagMatrixResult.fromJson(Map<String, dynamic>.from(res));
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

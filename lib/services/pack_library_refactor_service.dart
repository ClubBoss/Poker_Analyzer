import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../core/training/generation/yaml_reader.dart';
import '../core/training/generation/yaml_writer.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'pack_matrix_config.dart';

class PackLibraryRefactorService {
  const PackLibraryRefactorService();

  Future<int> refactorAll({String path = 'training_packs/library'}) async {
    if (!kDebugMode) return 0;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$path');
    if (!dir.existsSync()) return 0;
    final matrix = await const PackMatrixConfig().loadMatrix();
    const reader = YamlReader();
    const writer = YamlWriter();
    var count = 0;
    for (final f in dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((e) => e.path.toLowerCase().endsWith('.yaml'))) {
      Map<String, dynamic> map;
      try {
        map = reader.read(await f.readAsString());
      } catch (_) {
        continue;
      }
      final tpl = TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(map));
      var changed = false;
      final tags = <String>{
        for (final t in tpl.tags) t.toString().trim().toLowerCase()
      }..removeWhere((t) => t.isEmpty);
      if (!listEquals(tags.toList(), tpl.tags)) {
        tpl.tags
          ..clear()
          ..addAll(tags);
        changed = true;
      }
      if ((tpl.audience == null || tpl.audience!.isEmpty) && tpl.tags.isNotEmpty) {
        final aud = _detectAudience(tpl.tags, matrix);
        if (aud != null) {
          tpl.audience = aud;
          changed = true;
        }
      }
      if (map['evScore'] != null && tpl.meta['evScore'] == null) {
        tpl.meta['evScore'] = map['evScore'];
        changed = true;
      }
      if (map['icmScore'] != null && tpl.meta['icmScore'] == null) {
        tpl.meta['icmScore'] = map['icmScore'];
        changed = true;
      }
      if (changed) {
        await writer.write(tpl.toJson(), f.path);
        count++;
      }
    }
    return count;
  }

  String? _detectAudience(List<String> tags, List<(String, List<String>)> matrix) {
    final res = <String>{};
    for (final item in matrix) {
      for (final t in item.$2) {
        if (tags.contains(t.trim().toLowerCase())) {
          res.add(item.$1);
          break;
        }
      }
    }
    return res.length == 1 ? res.first : null;
  }
}

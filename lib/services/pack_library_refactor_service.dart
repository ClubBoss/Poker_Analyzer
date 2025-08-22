import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../core/training/generation/yaml_reader.dart';
import '../core/training/generation/yaml_writer.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'pack_matrix_config.dart';

class PackLibraryRefactorService {
  PackLibraryRefactorService();

  Future<int> refactorAll({String path = 'training_packs/library'}) async {
    if (!kDebugMode) return 0;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$path');
    if (!dir.existsSync()) return 0;
    final matrix = await const PackMatrixConfig().loadMatrix();
    const reader = YamlReader();
    const writer = YamlWriter();
    final seen = <String, String>{};
    var refactored = 0;
    var removed = 0;
    for (final f
        in dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((e) => e.path.toLowerCase().endsWith('.yaml'))) {
      Map<String, dynamic> map;
      try {
        final yaml = await f.readAsString();
        map = reader.read(yaml);
      } catch (_) {
        continue;
      }
      final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
      final tags = <String>{
        for (final t in tpl.tags) t.toString().trim().toLowerCase(),
      }..removeWhere((t) => t.isEmpty);
      tpl.tags
        ..clear()
        ..addAll(tags);
      if ((tpl.audience == null || tpl.audience!.isEmpty) &&
          tpl.tags.isNotEmpty) {
        final aud = _detectAudience(tpl.tags, matrix);
        if (aud != null) tpl.audience = aud;
      }
      if (map['evScore'] != null && tpl.meta['evScore'] == null) {
        tpl.meta['evScore'] = map['evScore'];
      }
      if (map['icmScore'] != null && tpl.meta['icmScore'] == null) {
        tpl.meta['icmScore'] = map['icmScore'];
      }
      final meta = Map<String, dynamic>.from(tpl.meta)
        ..removeWhere(
          (k, v) =>
              v == null ||
              (v is String && v.isEmpty) ||
              (v is List && v.isEmpty) ||
              (v is Map && v.isEmpty),
        );
      for (final k in ['createdAt', 'source', 'notes']) {
        final v = meta[k];
        if (v == null || (v is String && v.isEmpty)) meta.remove(k);
      }
      tpl.meta
        ..clear()
        ..addAll(meta);
      final spotHashes = [
        for (final s in tpl.spots)
          sha1.convert(utf8.encode(jsonEncode(s.hand.toJson()))).toString(),
      ]..sort();
      final key = '${tpl.tags.join(',')}-${spotHashes.join()}';
      if (seen.containsKey(key)) {
        try {
          f.deleteSync();
          removed++;
        } catch (_) {}
        continue;
      }
      seen[key] = f.path;
      await writer.write(_orderedMap(tpl), f.path);
      refactored++;
    }
    return refactored + removed;
  }

  String? _detectAudience(
    List<String> tags,
    List<(String, List<String>)> matrix,
  ) {
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

  Map<String, dynamic> _orderedMap(TrainingPackTemplateV2 tpl) {
    final json = tpl.toJson();
    json['title'] = json.remove('name');
    final map = <String, dynamic>{};
    for (final k in ['id', 'title', 'tags', 'meta', 'spots']) {
      if (json.containsKey(k)) map[k] = json.remove(k);
    }
    for (final e in json.entries) {
      map[e.key] = e.value;
    }
    return map;
  }
}

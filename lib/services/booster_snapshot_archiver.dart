import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../models/v2/training_pack_template_v2.dart';

/// Handles archiving of generated booster packs as YAML files.
class BoosterSnapshotArchiver {
  const BoosterSnapshotArchiver();

  /// Saves [pack] to `yaml_out/booster_archive` using a timestamped filename.
  Future<File?> archive(TrainingPackTemplateV2 pack,
      {String dir = 'yaml_out/booster_archive'}) async {
    if (!kDebugMode) return null;
    final id = pack.id.trim();
    if (id.isEmpty) return null;
    final directory = Directory(dir);
    await directory.create(recursive: true);
    var ts = DateFormat('yyyyMMddTHHmmss').format(DateTime.now());
    var file = File(p.join(directory.path, '${id}__$ts.bak.yaml'));
    // Ensure unique filename in case of collisions.
    while (await file.exists()) {
      ts = DateFormat('yyyyMMddTHHmmss').format(DateTime.now());
      file = File(p.join(directory.path, '${id}__$ts.bak.yaml'));
    }
    await file.writeAsString(pack.toYamlString());
    return file;
  }

  /// Loads archived versions of a booster pack by [id]. Most recent first.
  Future<List<File>> loadHistory(String id,
      {String dir = 'yaml_out/booster_archive'}) async {
    final directory = Directory(dir);
    if (!directory.existsSync()) return [];
    final files = directory
        .listSync()
        .whereType<File>()
        .where((f) =>
            f.path.endsWith('.bak.yaml') &&
            p.basename(f.path).startsWith('$id__'))
        .toList()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files;
  }
}

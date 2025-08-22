import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../models/v2/training_pack_template_v2.dart';
import 'booster_thematic_tagger.dart';

/// Exports YAML booster packs into thematic clusters.
class BoosterPackClusterExporter {
  BoosterPackClusterExporter();

  /// Reads all YAML files from [src] (defaults to `/packs`),
  /// detects thematic tags and copies packs into
  /// `build/cluster_<tag>` directories under [dst].
  Future<int> export({String src = '/packs', String dst = 'build'}) async {
    if (!kDebugMode) return 0;
    final directory = Directory(src);
    if (!directory.existsSync()) return 0;
    final files = directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'));
    var count = 0;
    for (final file in files) {
      try {
        final yaml = await file.readAsString();
        final pack = TrainingPackTemplateV2.fromYamlAuto(yaml);
        final tags = const BoosterThematicTagger().suggestThematicTags(pack);
        for (final tag in tags) {
          final dir = Directory(p.join(dst, 'cluster_${_slug(tag)}'));
          await dir.create(recursive: true);
          await file.copy(p.join(dir.path, p.basename(file.path)));
        }
        count++;
      } catch (_) {}
    }
    return count;
  }

  String _slug(String tag) =>
      tag.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}

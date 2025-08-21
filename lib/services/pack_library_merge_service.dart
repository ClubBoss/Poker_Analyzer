import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'training_pack_index_writer.dart';

class PackLibraryMergeService {
  const PackLibraryMergeService();

  Future<(int success, int failed)> mergeAll(
    List<String> paths, {
    bool clean = false,
  }) async {
    if (!kDebugMode) return (0, 0);
    final docs = await getApplicationDocumentsDirectory();
    final libDir = Directory('${docs.path}/training_packs/library');
    await libDir.create(recursive: true);
    if (clean) {
      for (final f in libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((e) => e.path.toLowerCase().endsWith('.yaml'))) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }
    final hashes = <String>{};
    final ids = <String>{};
    const reader = YamlReader();
    for (final f in libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((e) => e.path.toLowerCase().endsWith('.yaml'))) {
      try {
        final bytes = await f.readAsBytes();
        hashes.add(sha1.convert(bytes).toString());
        final map = reader.read(utf8.decode(bytes));
        final id = map['id']?.toString();
        if (id != null && id.isNotEmpty) ids.add(id);
      } catch (_) {}
    }
    var success = 0;
    var failed = 0;
    for (final path in paths) {
      final dir = Directory(path);
      if (!dir.existsSync()) continue;
      for (final f in dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((e) => e.path.toLowerCase().endsWith('.yaml'))) {
        try {
          final bytes = await f.readAsBytes();
          final hash = sha1.convert(bytes).toString();
          if (hashes.contains(hash)) continue;
          final yaml = utf8.decode(bytes);
          final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
          if (ids.contains(tpl.id)) continue;
          final dst = File(p.join(libDir.path, p.basename(f.path)));
          await dst.writeAsBytes(bytes, flush: true);
          hashes.add(hash);
          ids.add(tpl.id);
          success++;
        } catch (_) {
          failed++;
        }
      }
    }
    await const TrainingPackIndexWriter().writeIndex(
      src: libDir.path,
      out: p.join(libDir.path, 'library_index.json'),
      md: p.join(libDir.path, 'library_index.md'),
    );
    return (success, failed);
  }
}

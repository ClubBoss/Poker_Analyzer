import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/v2/training_pack_template_v2.dart';
import 'training_pack_index_writer.dart';

class PackLibraryImportService {
  const PackLibraryImportService();

  Future<(int success, int failed)> importFromExternalDir([
    String path = '/import',
  ]) async {
    if (!kDebugMode) return (0, 0);
    final srcDir = Directory(path);
    if (!srcDir.existsSync()) return (0, 0);
    final docs = await getApplicationDocumentsDirectory();
    final libDir = Directory('${docs.path}/training_packs/library');
    await libDir.create(recursive: true);
    final existingFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'))
        .toList();
    final names = <String>{
      for (final f in existingFiles) f.path.split(Platform.pathSeparator).last,
    };
    final hashes = <String>{
      for (final f in existingFiles)
        md5.convert(f.readAsBytesSync()).toString(),
    };
    var success = 0;
    var failed = 0;
    for (final f in srcDir.listSync().whereType<File>().where(
      (e) => e.path.toLowerCase().endsWith('.yaml'),
    )) {
      final name = f.path.split(Platform.pathSeparator).last;
      if (names.contains(name)) continue;
      try {
        final bytes = await f.readAsBytes();
        final hash = md5.convert(bytes).toString();
        if (hashes.contains(hash)) continue;
        final yaml = utf8.decode(bytes);
        TrainingPackTemplateV2.fromYamlAuto(yaml);
        await File(p.join(libDir.path, name)).writeAsBytes(bytes, flush: true);
        names.add(name);
        hashes.add(hash);
        success++;
      } catch (_) {
        failed++;
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

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';

class PackLibraryDuplicateCleaner {
  PackLibraryDuplicateCleaner();

  Future<int> clean(String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!dir.existsSync()) return 0;
    const reader = YamlReader();
    final ids = <String, File>{};
    final hashes = <String, File>{};
    var removed = 0;
    for (final f
        in dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((e) => e.path.toLowerCase().endsWith('.yaml'))) {
      try {
        final yaml = await f.readAsString();
        final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
        final map = reader.read(yaml);
        final json = jsonEncode(tpl.toJson());
        if (ids.containsKey(tpl.id) || hashes.containsKey(json)) {
          await f.delete();
          removed++;
          continue;
        }
        ids[tpl.id] = f;
        hashes[json] = f;
      } catch (_) {}
    }
    return removed;
  }

  Future<int> removeDuplicates({String path = 'training_packs/library'}) async {
    if (!kDebugMode) return 0;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$path');
    if (!dir.existsSync()) return 0;
    final hashes = <String, File>{};
    var removed = 0;
    for (final f
        in dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((e) => e.path.toLowerCase().endsWith('.yaml'))) {
      final bytes = await f.readAsBytes();
      final hash = sha1.convert(bytes).toString();
      final exist = hashes[hash];
      if (exist == null) {
        hashes[hash] = f;
      } else {
        try {
          f.deleteSync();
          removed++;
        } catch (_) {}
      }
    }
    return removed;
  }
}

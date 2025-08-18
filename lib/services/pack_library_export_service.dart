import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'yaml_validation_service.dart';

class PackLibraryExportService {
  const PackLibraryExportService();

  Future<int> exportAll({String target = '/export'}) async {
    if (!kDebugMode) return 0;
    final docs = await getApplicationDocumentsDirectory();
    final libDir = Directory('${docs.path}/training_packs/library');
    if (!libDir.existsSync()) return 0;
    final dst = Directory(target);
    await dst.create(recursive: true);
    final errors = await const YamlValidationService().validateAll(
      dir: libDir.path,
    );
    final invalid = {for (final e in errors) File(e.$1).path};
    var count = 0;
    for (final f
        in libDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.toLowerCase().endsWith('.yaml'))) {
      if (invalid.contains(f.path)) continue;
      await f.copy(p.join(dst.path, p.basename(f.path)));
      count++;
    }
    for (final name in ['library_index.json', 'coverage_report.json']) {
      final f = File(p.join(libDir.path, name));
      if (f.existsSync()) {
        await f.copy(p.join(dst.path, name));
      }
    }
    return count;
  }
}

import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class PackLibraryDuplicateCleaner {
  const PackLibraryDuplicateCleaner();

  Future<int> removeDuplicates({String path = 'training_packs/library'}) async {
    if (!kDebugMode) return 0;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$path');
    if (!dir.existsSync()) return 0;
    final hashes = <String, File>{};
    var removed = 0;
    for (final f in dir
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

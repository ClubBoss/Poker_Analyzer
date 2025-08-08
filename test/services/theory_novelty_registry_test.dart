import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/theory_novelty_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('records and detects duplicates', () async {
    final cacheDir = Directory('test_cache');
    if (cacheDir.existsSync()) cacheDir.deleteSync(recursive: true);
    final path = 'test_cache/theory_bundles.json';
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
    final reg = TheoryNoveltyRegistry(path: path);
    await reg.record('u1', ['a', 'b'], ['t1', 't2']);
    final dup = await reg.isRecentDuplicate('u1', ['a', 'b'], ['t1', 't2']);
    expect(dup, isTrue);
    final notDup = await reg.isRecentDuplicate('u1', ['a', 'b'], ['t1']);
    expect(notDup, isFalse);
  });
}

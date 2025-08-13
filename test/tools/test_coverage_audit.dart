import 'dart:io';
import 'package:path/path.dart' as p;

/// Lists public services and models in `lib/` without matching tests.
///
/// Scans `lib/services`, `lib/models/v2`, and `lib/core` directories and
/// searches for Dart files that do not have a corresponding `*_test.dart`
/// file under the `test/` directory.
void main() {
  final libDirs = [
    Directory('lib/services'),
    Directory(p.join('lib', 'models', 'v2')),
    Directory('lib/core'),
  ];
  final testRoot = Directory('test');

  // Collect all existing test file relative paths.
  final testFiles = testRoot
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('_test.dart'))
      .map((f) => p.relative(f.path, from: testRoot.path))
      .toSet();

  final missing = <String>[];

  for (final dir in libDirs) {
    if (!dir.existsSync()) continue;
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final base = p.basename(entity.path);
      if (base.startsWith('_')) continue; // Skip private files.
      final relative = p.relative(entity.path, from: 'lib');
      final expectedTest = relative.replaceFirst('.dart', '_test.dart');
      if (!testFiles.contains(expectedTest)) {
        missing.add(relative);
      }
    }
  }

  if (missing.isEmpty) {
    print('All services and models have tests.');
  } else {
    print('Missing tests for:');
    for (final path in missing..sort()) {
      print('- $path');
    }
  }
}

import 'dart:io';

import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';

/// Validates all YAML pack templates in the project.
///
/// Scans [assets/packs] and [assets/precompiled_packs] directories for YAML
/// files and attempts to parse each one as a [TrainingPackTemplateV2].
///
/// For every file the validator checks that `id`, `spots`, `bb` and `gameType`
/// fields are present. The script prints the path and an error description for
/// each invalid file. If any file fails validation the process exits with code
/// 1, otherwise it exits with code 0.
void main() {
  final dirs = [
    Directory('assets/packs'),
    Directory('assets/precompiled_packs'),
  ];

  var hasError = false;

  for (final dir in dirs) {
    if (!dir.existsSync()) continue;
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'));
    for (final file in files) {
      try {
        final yaml = file.readAsStringSync();
        final pack = TrainingPackTemplateV2.fromYaml(yaml);
        final missing = <String>[];
        if (pack.id.isEmpty) missing.add('id');
        if (pack.spots.isEmpty) missing.add('spots');
        if (pack.bb <= 0) missing.add('bb');
        // gameType is non-nullable but verify the YAML specified a value other
        // than the default empty name.
        if (pack.gameType.name.isEmpty) missing.add('gameType');
        if (missing.isNotEmpty) {
          stderr.writeln('${file.path}: missing ${missing.join(', ')}');
          hasError = true;
        }
      } catch (e) {
        stderr.writeln('${file.path}: $e');
        hasError = true;
      }
    }
  }

  if (hasError) {
    exit(1);
  } else {
    stdout.writeln('All packs are valid');
    exit(0);
  }
}

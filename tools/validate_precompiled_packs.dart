import 'dart:io';

import 'package:poker_analyzer/utils/training_pack_yaml_codec_v2.dart';

/// Validates all precompiled training pack YAML files.
///
/// Scans the [assets/precompiled_packs] directory and tries to decode every
/// `.yaml` file using [TrainingPackYamlCodecV2]. Prints a summary of the
/// validation results and exits with code 1 if any file fails to decode.
void main() {
  final dir = Directory('assets/precompiled_packs');
  if (!dir.existsSync()) {
    stdout.writeln('assets/precompiled_packs not found');
    exit(0);
  }

  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.yaml'));

  const codec = TrainingPackYamlCodecV2();
  var passed = 0;
  var failed = 0;

  for (final file in files) {
    try {
      final yaml = file.readAsStringSync();
      codec.decode(yaml);
      stdout.writeln('✓ ${file.path}');
      passed++;
    } catch (e) {
      stderr.writeln('✗ ${file.path}: $e');
      failed++;
    }
  }

  stdout.writeln('Validation complete: $passed passed, $failed failed');
  exit(failed > 0 ? 1 : 0);
}


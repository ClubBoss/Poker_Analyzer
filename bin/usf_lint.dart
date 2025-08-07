import 'dart:io';

import 'package:poker_analyzer/core/models/spot_seed/spot_seed_codec.dart';
import 'package:poker_analyzer/core/models/spot_seed/spot_seed_validator.dart';

/// Command line tool to lint YAML seeds using the Unified Spot Seed Format.
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stdout.writeln('Usage: usf_lint <directory>');
    exit(64);
  }

  final dir = Directory(args.first);
  if (!await dir.exists()) {
    stderr.writeln('Directory not found: ${dir.path}');
    exit(64);
  }

  final codec = const SpotSeedCodec();
  final validator = const SpotSeedValidator();
  var hasErrors = false;

  await for (final entity in dir.list(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.yaml') && !entity.path.endsWith('.yml')) {
      continue;
    }
    final content = await entity.readAsString();
    try {
      final seed = codec.fromYaml(content);
      final issues = validator.validate(seed);
      for (final issue in issues) {
        stdout.writeln(
          '${entity.path}: ${issue.severity.toUpperCase()} ${issue.code} - ${issue.message}',
        );
      }
      if (issues.any((i) => i.severity == 'error')) {
        hasErrors = true;
      }
    } catch (e) {
      stderr.writeln('${entity.path}: failed to parse - $e');
      hasErrors = true;
    }
  }

  if (hasErrors) {
    exit(1);
  }
}

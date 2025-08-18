// tool/theory_manifest_cli.dart
//
// Standalone theory manifest generator.
// Scans specified directories for *.yaml files and writes theory_manifest.json.
// Does NOT import application code (lib/) to avoid Flutter compilation errors.

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final outIndex = args.indexOf('--out');
  final outPath = (outIndex != -1 && outIndex + 1 < args.length)
      ? args[outIndex + 1]
      : 'theory_manifest.json';

  // Parse --dir arguments
  final dirs = <String>[];
  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--dir' && i + 1 < args.length) {
      dirs.add(args[i + 1]);
      i++;
    }
  }

  if (dirs.isEmpty) {
    stderr.writeln(
      'Usage: dart run tool/theory_manifest_cli.dart --dir <path> [--dir <path> ...] [--out theory_manifest.json]',
    );
    exit(2);
  }

  final repoRoot = Directory.current.path;
  final Map<String, dynamic> manifest = {};

  for (final dir in dirs) {
    final directory = Directory(dir);
    if (!directory.existsSync()) continue;

    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File && entity.path.toLowerCase().endsWith('.yaml')) {
        final relPath = p.relative(entity.path, from: repoRoot);
        final bytes = await entity.readAsBytes();
        final sha = sha1.convert(bytes).toString();
        final stat = await entity.stat();

        manifest[relPath] = {
          "path": relPath,
          "sha1": sha,
          "sizeBytes": stat.size,
          "mtime": stat.modified.toUtc().toIso8601String(),
        };
      }
    }
  }

  final outFile = File(outPath);
  await outFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest),
  );

  stdout.writeln(
    '✅ Wrote ${manifest.length} entries to $outPath from ${dirs.length} directories.',
  );
}

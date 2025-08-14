import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:poker_analyzer/ev/jam_fold_evaluator.dart';

Future<void> main(List<String> args) async {
  String? inPath;
  String? outPath;
  String? dirPath;
  String? glob;
  var dryRun = false;
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--in' && i + 1 < args.length) {
      inPath = args[++i];
    } else if (arg == '--out' && i + 1 < args.length) {
      outPath = args[++i];
    } else if (arg == '--dir' && i + 1 < args.length) {
      dirPath = args[++i];
    } else if (arg == '--glob' && i + 1 < args.length) {
      glob = args[++i];
    } else if (arg == '--dry-run') {
      dryRun = true;
    } else {
      stderr.writeln('Unknown or incomplete argument: $arg');
      exitCode = 64;
      return;
    }
  }

  final modes = [inPath, dirPath, glob].whereType<String>();
  if (modes.length != 1) {
    stderr.writeln('Specify exactly one of --in, --dir, or --glob');
    exitCode = 64;
    return;
  }

  if ((dirPath != null || glob != null) && outPath != null) {
    stderr.writeln('--out is not supported with --dir or --glob');
    exitCode = 64;
    return;
  }

  const merger = JamFoldMerger();
  var scanned = 0;
  var changed = 0;

  Future<void> handle(String inFile, String outFile) async {
    scanned++;
    if (await merger.processFile(inFile, outFile, dryRun: dryRun)) {
      changed++;
    }
  }

  if (inPath != null) {
    outPath ??= inPath;
    await handle(inPath, outPath);
  } else if (dirPath != null) {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      stderr.writeln('Directory not found: $dirPath');
      exitCode = 64;
      return;
    }
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.json')) {
        await handle(entity.path, entity.path);
      }
    }
  } else if (glob != null) {
    final regex = _globToRegExp(glob!);
    final root = Directory.current.path;
    await for (final entity in Directory.current.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final rel = p.relative(entity.path, from: root).replaceAll('\\', '/');
      if (regex.hasMatch(rel)) {
        await handle(entity.path, entity.path);
      }
    }
  }

  final skipped = scanned - changed;
  print('Scanned $scanned files: $changed changed, $skipped skipped');
}

RegExp _globToRegExp(String pattern) {
  var escaped = RegExp.escape(pattern);
  escaped = escaped.replaceAll('\\*\\*', '::DOUBLE_STAR::');
  escaped = escaped.replaceAll('\\*', '[^/]*');
  escaped = escaped.replaceAll('::DOUBLE_STAR::', '.*');
  return RegExp('^' + escaped + r'\$');
}

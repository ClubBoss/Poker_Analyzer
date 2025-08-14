import 'dart:io';

import 'package:poker_analyzer/ev/jam_fold_evaluator.dart';

Future<void> main(List<String> args) async {
  String? inPath;
  String? outPath;
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--in' && i + 1 < args.length) {
      inPath = args[++i];
    } else if (arg == '--out' && i + 1 < args.length) {
      outPath = args[++i];
    } else {
      stderr.writeln('Unknown or incomplete argument: $arg');
      exitCode = 64;
      return;
    }
  }
  if (inPath == null) {
    stderr.writeln('Missing --in path');
    exitCode = 64;
    return;
  }
  outPath ??= inPath;
  const merger = JamFoldMerger();
  await merger.processFile(inPath, outPath);
}

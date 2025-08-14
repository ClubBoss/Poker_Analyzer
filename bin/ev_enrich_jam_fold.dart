import 'dart:io';

import 'package:args/args.dart';

import 'package:poker_analyzer/ev/jam_fold_evaluator.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('in', help: 'Input JSON file')
    ..addOption('out', help: 'Output JSON file');
  final result = parser.parse(args);
  final inPath = result['in'] as String?;
  if (inPath == null) {
    stderr.writeln('Missing --in path');
    exitCode = 64;
    return;
  }
  final outPath = result['out'] as String? ?? inPath;
  const merger = JamFoldMerger();
  await merger.processFile(inPath, outPath);
}

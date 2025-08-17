import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:poker_analyzer/core/error_logger.dart';
import 'package:poker_analyzer/core/training/generation/smart_path_compiler.dart';

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    ErrorLogger.instance.logError(
      'Usage: dart run tool/compile_path.dart <spec.txt> <packs_dir>',
    );
    exit(1);
  }

  final specFile = File(args[0]);
  final packsDir = Directory(args[1]);

  if (!specFile.existsSync()) {
    ErrorLogger.instance.logError('File not found: ${specFile.path}');
    exit(1);
  }

  if (!packsDir.existsSync()) {
    ErrorLogger.instance.logError('Directory not found: ${packsDir.path}');
    exit(1);
  }

  final lines = specFile.readAsLinesSync();
  final compiler = SmartPathCompiler();
  late String yaml;
  try {
    yaml = compiler.compile(lines, packsDir);
  } catch (e) {
    final msg = e.toString();
    for (final line in msg.split(',')) {
      ErrorLogger.instance.logError(line.trim());
    }
    exit(1);
  }

  final outDir = Directory('compiled');
  await outDir.create(recursive: true);
  final outFile = File(p.join(outDir.path, 'path.yaml'));
  outFile.writeAsStringSync('$yaml\n');
  ErrorLogger.instance.logError('Wrote ${outFile.path}');
}

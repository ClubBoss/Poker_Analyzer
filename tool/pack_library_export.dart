import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:poker_analyzer/models/training_pack_model.dart';
import 'package:poker_analyzer/services/training_pack_library_importer.dart';
import 'package:poker_analyzer/services/training_pack_library_exporter.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/pack_library_export.dart <outputDir>');
    exit(64);
  }
  final outDir = Directory(args[0]);
  await outDir.create(recursive: true);

  final importer = TrainingPackLibraryImporter();
  final root = Directory('assets/packs/v2');
  final packs = <TrainingPackModel>[];
  if (root.existsSync()) {
    final dirs = root.listSync().whereType<Directory>();
    for (final d in dirs) {
      packs.addAll(await importer.loadFromDirectory(d.path));
    }
  }

  if (packs.isEmpty) {
    stdout.writeln('No packs found.');
    return;
  }

  const exporter = TrainingPackLibraryExporter();
  final files = await exporter.saveToDirectory(packs, outDir.path);
  stdout.writeln(
    'Exported ${files.length} packs to ${p.normalize(outDir.path)}',
  );
}

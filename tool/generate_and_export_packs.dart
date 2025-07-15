import 'dart:io';

import 'package:args/args.dart';
import 'package:poker_analyzer/core/training/generation/pack_library_generator.dart';
import 'package:poker_analyzer/core/training/generation/pack_library_exporter.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('config', defaultsTo: 'tool/config.yaml');
  final argResults = parser.parse(args);
  final configPath = argResults['config'] as String;
  stdout.writeln('Using config: $configPath');
  const outputDir = 'tool/output';
  final file = File(configPath);
  if (!file.existsSync()) {
    stderr.writeln('Config not found: $configPath');
    exit(1);
  }
  String source;
  try {
    source = file.readAsStringSync();
  } catch (e) {
    stderr.writeln('Failed to read $configPath');
    exit(1);
  }
  final generator = PackLibraryGenerator();
  late final List<TrainingPackTemplate> packs;
  try {
    packs = generator.generateFromYaml(source);
  } catch (e) {
    stderr.writeln('Invalid config');
    exit(1);
  }
  await Directory(outputDir).create(recursive: true);
  final exporter = const PackLibraryExporter();
  List<String> paths;
  try {
    paths = await exporter.export(packs, outputDir);
  } catch (e) {
    stderr.writeln('Export failed');
    exit(1);
  }
  stdout.writeln('Generated ${paths.length} files in $outputDir/');
}

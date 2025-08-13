import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:poker_analyzer/models/training_pack_template_set.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/services/autogen_pack_generator_service.dart';
import 'package:poker_analyzer/services/yaml_pack_exporter.dart';
import 'package:poker_analyzer/core/training/export/training_pack_exporter_v2.dart';

class _AssetPackExporter extends TrainingPackExporterV2 {
  final String outDir;
  const _AssetPackExporter(this.outDir);

  @override
  Future<File> exportToFile(TrainingPackTemplateV2 pack,
      {String? fileName}) async {
    final dir = Directory(outDir);
    await dir.create(recursive: true);
    final safeName = (fileName ?? pack.name)
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(' ', '_');
    final file = File(p.join(dir.path, '$safeName.yaml'));
    await file.writeAsString(exportYaml(pack));
    return file;
  }
}

Future<void> main(List<String> args) async {
  // Reset duplicate log
  await File('skipped_duplicates.log').writeAsString('');

  // Load template sets
  final templatesDir = Directory('assets/templates/postflop_sets');
  final sets = <TrainingPackTemplateSet>[];
  if (await templatesDir.exists()) {
    await for (final entity in templatesDir.list()) {
      if (entity is File &&
          (entity.path.endsWith('.yaml') || entity.path.endsWith('.yml'))) {
        final yaml = await entity.readAsString();
        sets.add(TrainingPackTemplateSet.fromYaml(yaml));
      }
    }
  }

  final existingYamlPath = 'assets/packs/v2/postflop/generated';
  final outputDir = p.join(existingYamlPath, 'hyperscale');

  final exporter = YamlPackExporter(delegate: _AssetPackExporter(outputDir));
  final service = AutogenPackGeneratorService(exporter: exporter);

  final files = await service.generate(
    sets,
    existingYamlPath: existingYamlPath,
  );

  var generatedSpots = 0;
  for (final f in files) {
    final yaml = await f.readAsString();
    final tpl = TrainingPackTemplateV2.fromYaml(yaml);
    generatedSpots += tpl.spotCount;
  }

  final skippedLines = await File('skipped_duplicates.log').readAsLines();
  final skippedCount = skippedLines.where((l) => l.trim().isNotEmpty).length;

  stdout.writeln(
      'Generated $generatedSpots spots, skipped $skippedCount duplicates, created ${files.length} YAML files');
}

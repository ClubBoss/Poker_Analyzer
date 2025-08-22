import 'dart:io';

import '../core/error_logger.dart';
import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';

class TheoryYamlImporter {
  TheoryYamlImporter({ErrorLogger? logger})
    : _logger = logger ?? ErrorLogger.instance;

  final ErrorLogger _logger;

  Future<List<TrainingPackTemplateV2>> importFromDirectory(
    String dirPath,
  ) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return <TrainingPackTemplateV2>[];

    const reader = YamlReader();
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'));

    final templates = <TrainingPackTemplateV2>[];

    for (final file in files) {
      try {
        final yaml = await file.readAsString();
        final map = reader.read(yaml);
        final meta = map['meta'];
        final isTheory = map['type']?.toString().toLowerCase() == 'theory';
        final isBooster = meta is Map && meta['booster'] == true;
        if (!isTheory && !isBooster) continue;
        templates.add(TrainingPackTemplateV2.fromYamlString(yaml));
      } catch (e, st) {
        _logger.logError('Failed to load ${file.path}', e, st);
      }
    }

    return templates;
  }
}

import 'dart:io';

import '../core/training/generation/yaml_reader.dart';
import '../core/training/engine/training_type_engine.dart';
import '../models/v2/training_pack_template_v2.dart';

class TheoryExportValidator {
  TheoryExportValidator();

  Future<List<(String, String)>> validateAll({
    String dir = 'yaml_out/theory',
  }) async {
    final errors = <(String, String)>[];
    final directory = Directory(dir);
    if (!directory.existsSync()) return errors;
    const reader = YamlReader();
    final ids = <String, String>{};
    final files = directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'));
    for (final file in files) {
      final path = file.path;
      try {
        final map = reader.read(await file.readAsString());
        final tpl = TrainingPackTemplateV2.fromJson(
          Map<String, dynamic>.from(map),
        );

        final id = tpl.id.trim();
        if (id.isEmpty) {
          errors.add((path, 'missing_id'));
        } else {
          final prev = ids[id];
          if (prev != null) {
            errors.add((path, 'duplicate_id'));
            errors.add((prev, 'duplicate_id'));
          } else {
            ids[id] = path;
          }
        }

        if (tpl.name.trim().isEmpty) errors.add((path, 'missing_title'));
        if (tpl.trainingType != TrainingType.theory) {
          errors.add((path, 'bad_trainingType:${tpl.trainingType.name}'));
        }
        if (tpl.tags.isEmpty) errors.add((path, 'missing_tags'));
        if (tpl.spots.isEmpty) {
          errors.add((path, 'missing_spots'));
        } else {
          for (final s in tpl.spots) {
            if (s.id.trim().isEmpty) errors.add((path, 'spot_missing_id'));
            if (s.title.trim().isEmpty) {
              errors.add((path, 'spot_missing_title'));
            }
          }
        }
      } catch (_) {
        errors.add((path, 'parse_error'));
      }
    }
    return errors;
  }
}

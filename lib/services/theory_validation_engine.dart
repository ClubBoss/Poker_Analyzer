import 'dart:io';

import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'theory_pack_generator_service.dart';

/// Validates theory YAML files generated in `yaml_out/`.
class TheoryValidationEngine {
  TheoryValidationEngine();

  /// Returns a list of `(filePath, message)` tuples describing validation errors.
  Future<List<(String, String)>> validateAll({String dir = 'yaml_out'}) async {
    final errors = <(String, String)>[];
    final directory = Directory(dir);
    if (!directory.existsSync()) return errors;
    const reader = YamlReader();
    final files = directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'));
    for (final file in files) {
      try {
        final map = reader.read(await file.readAsString());
        final tpl = TrainingPackTemplateV2.fromJson(
          Map<String, dynamic>.from(map),
        );
        if (tpl.spots.isEmpty) {
          errors.add((file.path, 'missing_spot'));
          continue;
        }
        final spot = tpl.spots.first;
        if (spot.type != 'theory') {
          errors.add((file.path, 'bad_type'));
        }
        final exp = spot.explanation?.trim() ?? '';
        if (exp.length < 3) {
          errors.add((file.path, 'bad_explanation'));
        }
        if (spot.tags.isEmpty) {
          errors.add((file.path, 'missing_tags'));
        } else {
          for (final t in spot.tags) {
            if (!TheoryPackGeneratorService.tags.contains(t)) {
              errors.add((file.path, 'unknown_tag:$t'));
            }
          }
        }
      } catch (_) {
        errors.add((file.path, 'parse_error'));
      }
    }
    return errors;
  }
}

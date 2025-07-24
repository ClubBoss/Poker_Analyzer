import 'dart:io';
import 'package:path/path.dart' as p;

import 'learning_path_library_generator.dart';

class LearningPathPackValidator {
  const LearningPathPackValidator();

  List<String> validate(
    List<LearningPathStageTemplateInput> stages,
    Directory packsDir,
  ) {
    final files = packsDir.listSync(recursive: true);
    final names = <String>{};
    for (final f in files) {
      if (f is File && f.path.toLowerCase().endsWith('.yaml')) {
        names.add(p.basenameWithoutExtension(f.path));
      }
    }

    final errors = <String>[];
    for (final stage in stages) {
      if (!names.contains(stage.packId)) {
        errors.add('Missing pack: ${stage.packId}');
      }
      for (final sub in stage.subStages) {
        if (!names.contains(sub.packId)) {
          errors.add('Missing subStage pack: ${sub.packId}');
        }
      }
    }
    return errors;
  }
}

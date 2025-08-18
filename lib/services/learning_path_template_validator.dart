import '../models/learning_path_template_v2.dart';
import '../models/validation_issue.dart';
import '../models/pack_library.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../core/training/engine/training_type_engine.dart';

/// Validates a single [LearningPathTemplateV2].
class LearningPathTemplateValidator {
  const LearningPathTemplateValidator();

  /// Returns a list of validation issues for [path].
  List<ValidationIssue> validate(LearningPathTemplateV2 path) {
    final issues = <ValidationIssue>[];

    final ids = <String>{};
    for (final stage in path.stages) {
      final sid = stage.id.trim();
      if (sid.isEmpty) {
        issues.add(
          const ValidationIssue(type: 'error', message: 'empty_stage_id'),
        );
        continue;
      }
      if (!ids.add(sid)) {
        issues.add(
          ValidationIssue(type: 'error', message: 'duplicate_id:$sid'),
        );
      }
      if (stage.tags.isEmpty) {
        issues.add(
          ValidationIssue(type: 'error', message: 'missing_tags:$sid'),
        );
      }

      final pack = _findPack(stage.packId);
      if (pack == null) {
        issues.add(
          ValidationIssue(
            type: 'error',
            message: 'missing_pack:${stage.packId}',
          ),
        );
        continue;
      }
      if (pack.trainingType == TrainingType.theory) {
        final id = stage.theoryPackId?.trim() ?? '';
        if (id.isEmpty) {
          issues.add(
            ValidationIssue(
              type: 'error',
              message: 'missing_theory_pack_id:$sid',
            ),
          );
        } else if (_findPack(id) == null) {
          issues.add(
            ValidationIssue(type: 'error', message: 'bad_theory_pack:$id'),
          );
        }
      }
    }

    return issues;
  }

  TrainingPackTemplateV2? _findPack(String id) {
    return PackLibrary.main.getById(id) ?? PackLibrary.staging.getById(id);
  }
}

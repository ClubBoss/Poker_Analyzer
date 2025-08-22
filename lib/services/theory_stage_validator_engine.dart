import '../models/pack_library.dart';
import '../models/stage_type.dart';
import 'learning_path_stage_library.dart';

/// Validates theory stages against the main pack library.
class TheoryStageValidatorEngine {
  TheoryStageValidatorEngine();

  /// Returns a list of validation errors.
  List<String> validate() {
    final errors = <String>[];
    final library = LearningPathStageLibrary.instance;
    final stageIds = <String>{};
    for (final stage in library.stages) {
      if (!stageIds.add(stage.id)) {
        errors.add('duplicate_stage_id:${stage.id}');
      }
      if (stage.title.trim().isEmpty) {
        errors.add('empty_title:${stage.id}');
      }

      // Check for duplicate pack IDs within the stage and missing packs
      final packIds = <String>{};
      void checkPack(String id) {
        if (!packIds.add(id)) {
          errors.add('duplicate_pack_id:${stage.id}:$id');
        }
        if (PackLibrary.main.getById(id) == null) {
          errors.add('missing_pack:$id');
        }
      }

      checkPack(stage.packId);
      for (final sub in stage.subStages) {
        checkPack(sub.packId);
      }

      if (stage.type == StageType.theory && stage.subStages.isEmpty) {
        errors.add('no_sub_stages:${stage.id}');
      }
    }
    return errors;
  }
}

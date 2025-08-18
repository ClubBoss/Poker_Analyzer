import 'learning_path_stage_template_generator.dart';
import 'learning_path_library_generator.dart';

/// Strategy for assigning pack ids to sub stages.
abstract class PackAssignStrategy {
  String? resolve(String subStageId);
}

/// Assigns a constant [packId] when [subStageId] starts with [prefix].
class ByPrefixStrategy implements PackAssignStrategy {
  final String prefix;
  final String packId;
  const ByPrefixStrategy({required this.prefix, required this.packId});
  @override
  String? resolve(String subStageId) =>
      subStageId.startsWith(prefix) ? packId : null;
}

/// Resolves pack ids using [mapping] of prefixes to ids.
class ManualMapStrategy implements PackAssignStrategy {
  final Map<String, String> mapping;
  const ManualMapStrategy(this.mapping);
  @override
  String? resolve(String subStageId) {
    for (final entry in mapping.entries) {
      if (subStageId.startsWith(entry.key)) return entry.value;
    }
    return null;
  }
}

/// Utility assigning pack ids for sub stages based on [strategy].
class LearningPathAutoPackAssigner {
  const LearningPathAutoPackAssigner();

  List<LearningPathStageTemplateInput> assignPackIds(
    List<LearningPathStageTemplateInput> stages,
    PackAssignStrategy strategy,
  ) {
    final result = <LearningPathStageTemplateInput>[];
    for (final stage in stages) {
      final updatedSubs = <SubStageTemplateInput>[];
      for (final sub in stage.subStages) {
        final packId = sub.packId.isNotEmpty
            ? sub.packId
            : (strategy.resolve(sub.id) ?? sub.id);
        updatedSubs.add(
          SubStageTemplateInput(
            id: sub.id,
            packId: packId,
            title: sub.title,
            description: sub.description,
            minHands: sub.minHands,
            requiredAccuracy: sub.requiredAccuracy,
            unlockCondition: sub.unlockCondition,
          ),
        );
      }
      result.add(
        LearningPathStageTemplateInput(
          id: stage.id,
          title: stage.title,
          packId: stage.packId,
          description: stage.description,
          requiredAccuracy: stage.requiredAccuracy,
          minHands: stage.minHands,
          subStages: updatedSubs,
          unlockCondition: stage.unlockCondition,
          tags: stage.tags,
        ),
      );
    }
    return result;
  }
}

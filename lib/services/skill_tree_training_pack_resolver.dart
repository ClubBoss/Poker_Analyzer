import '../models/skill_tree.dart';
import '../models/skill_tree_node_model.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'pack_library_service.dart';
import 'skill_tree_unlock_evaluator.dart';

/// Resolves training packs for skill tree nodes using their [trainingPackId].
class SkillTreeTrainingPackResolver {
  final PackLibraryService _library;
  final SkillTreeUnlockEvaluator _unlockEvaluator;

  SkillTreeTrainingPackResolver({
    PackLibraryService? library,
    SkillTreeUnlockEvaluator? unlockEvaluator,
  }) : _library = library ?? PackLibraryService.instance,
       _unlockEvaluator = unlockEvaluator ?? SkillTreeUnlockEvaluator();

  /// Returns the training pack linked to [node] or `null` if none found.
  Future<TrainingPackTemplateV2?> getPackForNode(
    SkillTreeNodeModel node,
  ) async {
    final id = node.trainingPackId;
    if (id.isEmpty) return null;
    return _library.getById(id);
  }

  /// Returns a mapping of unlocked nodes in [tree] to their training packs.
  Future<Map<SkillTreeNodeModel, TrainingPackTemplateV2?>>
  getPacksForUnlockedNodes(SkillTree tree) async {
    final nodes = _unlockEvaluator.getUnlockedNodes(tree);
    final result = <SkillTreeNodeModel, TrainingPackTemplateV2?>{};
    for (final n in nodes) {
      result[n] = await getPackForNode(n);
    }
    return result;
  }
}

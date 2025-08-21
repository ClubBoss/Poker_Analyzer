import '../models/skill_tree.dart';
import '../models/skill_tree_node_model.dart';
import '../models/theory_mini_lesson_node.dart';
import 'mini_lesson_library_service.dart';
import 'skill_tree_unlock_evaluator.dart';

/// Resolves theory lessons for skill tree nodes using their [theoryLessonId].
class SkillTreeTheoryLessonResolver {
  final MiniLessonLibraryService _library;
  final SkillTreeUnlockEvaluator _unlockEvaluator;

  SkillTreeTheoryLessonResolver({
    MiniLessonLibraryService? library,
    SkillTreeUnlockEvaluator? unlockEvaluator,
  })  : _library = library ?? MiniLessonLibraryService.instance,
        _unlockEvaluator = unlockEvaluator ?? SkillTreeUnlockEvaluator();

  /// Returns the theory lesson linked to [node] or `null` if none found.
  TheoryMiniLessonNode? getLessonForNode(SkillTreeNodeModel node) {
    final id = node.theoryLessonId;
    if (id.isEmpty) return null;
    return _library.getById(id);
  }

  /// Returns a mapping of unlocked nodes in [tree] to their theory lessons.
  Future<Map<SkillTreeNodeModel, TheoryMiniLessonNode?>>
      getLessonsForUnlockedNodes(SkillTree tree) async {
    await _library.loadAll();
    final nodes = _unlockEvaluator.getUnlockedNodes(tree);
    final result = <SkillTreeNodeModel, TheoryMiniLessonNode?>{};
    for (final n in nodes) {
      result[n] = getLessonForNode(n);
    }
    return result;
  }
}

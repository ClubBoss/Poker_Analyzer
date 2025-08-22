import '../models/learning_branch_node.dart';
import '../models/learning_path_node.dart';
import '../models/theory_lesson_node.dart';
import '../models/theory_mini_lesson_node.dart';
import 'path_map_engine.dart';
import 'mistake_booster_progress_tracker.dart';

/// Decorates [LearningPathNode]s with recoveredFromMistake based on booster progress.
class MistakeBoosterPathNodeDecorator {
  final MistakeBoosterProgressTracker tracker;

  MistakeBoosterPathNodeDecorator({
    MistakeBoosterProgressTracker? tracker,
  }) : tracker = tracker ?? MistakeBoosterProgressTracker.instance;

  /// Returns a copy of [nodes] with recovered status applied.
  Future<List<LearningPathNode>> decorate(List<LearningPathNode> nodes) async {
    final recovered = await tracker.getCompletedTags();
    if (recovered.isEmpty) {
      return [for (final n in nodes) _clone(n)];
    }
    final tags = {for (final r in recovered) r.tag.toLowerCase()};
    return [for (final n in nodes) _decorateNode(n, tags)];
  }

  LearningPathNode _decorateNode(LearningPathNode node, Set<String> tags) {
    if (node is TheoryMiniLessonNode) {
      final flag = node.tags.any((t) => tags.contains(t.toLowerCase()));
      return TheoryMiniLessonNode(
        id: node.id,
        refId: node.refId,
        title: node.title,
        content: node.content,
        stage: node.stage,
        tags: List<String>.from(node.tags),
        nextIds: List<String>.from(node.nextIds),
        linkedPackIds: List<String>.from(node.linkedPackIds),
        recoveredFromMistake: flag,
      );
    }
    return _clone(node);
    return node;
  }

  LearningPathNode _clone(LearningPathNode node) {
    if (node is LearningBranchNode) {
      return LearningBranchNode(
        id: node.id,
        prompt: node.prompt,
        branches: Map<String, String>.from(node.branches),
        recoveredFromMistake: node.recoveredFromMistake,
      );
    } else if (node is TrainingStageNode) {
      return TrainingStageNode(
        id: node.id,
        nextIds: List<String>.from(node.nextIds),
        dependsOn: List<String>.from(node.dependsOn),
        recoveredFromMistake: node.recoveredFromMistake,
      );
    } else if (node is TheoryStageNode) {
      return TheoryStageNode(
        id: node.id,
        nextIds: List<String>.from(node.nextIds),
        dependsOn: List<String>.from(node.dependsOn),
        recoveredFromMistake: node.recoveredFromMistake,
      );
    } else if (node is TheoryLessonNode) {
      return TheoryLessonNode(
        id: node.id,
        refId: node.refId,
        title: node.title,
        content: node.content,
        nextIds: List<String>.from(node.nextIds),
        recoveredFromMistake: node.recoveredFromMistake,
      );
    } else if (node is TheoryMiniLessonNode) {
      return TheoryMiniLessonNode(
        id: node.id,
        refId: node.refId,
        title: node.title,
        content: node.content,
        tags: List<String>.from(node.tags),
        nextIds: List<String>.from(node.nextIds),
        linkedPackIds: List<String>.from(node.linkedPackIds),
        recoveredFromMistake: node.recoveredFromMistake,
        stage: node.stage,
      );
    }
    return node;
  }
}

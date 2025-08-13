import 'package:collection/collection.dart';

import '../models/learning_branch_node.dart';
import '../models/learning_path_node.dart';
import '../models/theory_lesson_node.dart';
import '../models/theory_mini_lesson_node.dart';
import 'learning_path_node_history.dart';
import 'path_map_engine.dart';

/// Dumps a formatted snapshot of the current PathMapEngine graph.
class LearningPathNodeGraphSnapshotService {
  const LearningPathNodeGraphSnapshotService({required this.engine});

  final PathMapEngine engine;

  /// Returns a formatted multiline snapshot of all nodes.
  String debugSnapshot() {
    final autoInjected =
        LearningPathNodeHistory.instance.getAutoInjectedIds().toSet();
    final buffer = StringBuffer();
    for (final node in engine.allNodes.sortedBy((n) => n.id)) {
      final marker = autoInjected.contains(node.id) ? '*' : '';
      final type = _typeOf(node);
      final next = _nextIds(node).join(', ');
      final depends = _dependsOn(node).join(', ');
      buffer.writeln(
          '${node.id}$marker [$type] nextIds: [$next] dependsOn: [$depends]');
    }
    return buffer.toString();
  }

  String _typeOf(LearningPathNode node) {
    if (node is LearningBranchNode) return 'Branch';
    if (node is TrainingStageNode) return 'Training';
    if (node is TheoryStageNode) return 'Theory';
    if (node is TheoryLessonNode) return 'Theory';
    if (node is TheoryMiniLessonNode) return 'Theory';
    return node.runtimeType.toString();
  }

  List<String> _nextIds(LearningPathNode node) {
    if (node is LearningBranchNode) {
      return node.branches.values.toList();
    }
    if (node is StageNode) return node.nextIds;
    if (node is TheoryLessonNode) return node.nextIds;
    if (node is TheoryMiniLessonNode) return node.nextIds;
    return const [];
  }

  List<String> _dependsOn(LearningPathNode node) {
    if (node is StageNode) return node.dependsOn;
    return const [];
  }
}

import '../models/learning_branch_node.dart';
import '../models/learning_path_node.dart';
import 'path_map_engine.dart';
import '../models/theory_lesson_node.dart';

/// Utility to validate learning path graphs.
class LearningPathValidator {
  const LearningPathValidator._();

  /// Returns list of error strings describing issues in [nodes].
  static List<String> validate(List<LearningPathNode> nodes) {
    if (nodes.isEmpty) return const [];

    final errors = <String>[];
    final idCounts = <String, int>{};
    final byId = <String, LearningPathNode>{};
    for (final n in nodes) {
      idCounts[n.id] = (idCounts[n.id] ?? 0) + 1;
      byId[n.id] = n;
    }

    for (final e in idCounts.entries) {
      if (e.value > 1) errors.add('Duplicate id: ${e.key}');
    }

    final incoming = <String, int>{for (final n in nodes) n.id: 0};
    final outgoing = <String, List<String>>{for (final n in nodes) n.id: []};

    for (final node in nodes) {
      if (node is LearningBranchNode) {
        for (final target in node.branches.values) {
          outgoing[node.id]!.add(target);
          if (!byId.containsKey(target)) {
            errors.add('Node ${node.id} references missing node $target');
          } else {
            incoming[target] = (incoming[target] ?? 0) + 1;
          }
        }
      } else if (node is StageNode || node is TheoryLessonNode) {
        final nextIds = node is StageNode
            ? node.nextIds
            : (node as TheoryLessonNode).nextIds;
        for (final next in nextIds) {
          outgoing[node.id]!.add(next);
          if (!byId.containsKey(next)) {
            errors.add('Node ${node.id} references missing node $next');
          } else {
            incoming[next] = (incoming[next] ?? 0) + 1;
          }
        }
      }
    }

    for (final id in byId.keys) {
      final out = outgoing[id] ?? const [];
      final inc = incoming[id] ?? 0;
      if (out.isEmpty && inc == 0) {
        errors.add('Node $id is disconnected');
      }
    }

    // cycle detection using DFS
    final color = <String, int>{};
    bool dfs(String id) {
      final state = color[id] ?? 0;
      if (state == 1) return true; // cycle found
      if (state == 2) return false;
      color[id] = 1;
      for (final next in outgoing[id]!) {
        if (byId.containsKey(next) && dfs(next)) return true;
      }
      color[id] = 2;
      return false;
    }

    for (final id in byId.keys) {
      if (color[id] != 2 && dfs(id)) {
        errors.add('Cycle detected at node $id');
      }
    }

    return errors;
  }
}

import '../models/learning_branch_node.dart';
import '../models/learning_path_node.dart';
import '../models/validation_issue.dart';
import 'graph_path_template_parser.dart';
import 'path_map_engine.dart';
import '../models/theory_lesson_node.dart';

/// Validates graph-based learning path YAML files.
class GraphPathTemplateValidator {
  final GraphPathTemplateParser parser;
  GraphPathTemplateValidator({GraphPathTemplateParser? parser})
    : parser = parser ?? GraphPathTemplateParser();

  /// Parses [yamlText] and validates the resulting nodes.
  Future<List<ValidationIssue>> validateYaml(String yamlText) async {
    final nodes = await parser.parseFromYaml(yamlText);
    return validate(nodes);
  }

  /// Validates [nodes] for structural consistency.
  List<ValidationIssue> validate(List<LearningPathNode> nodes) {
    final issues = <ValidationIssue>[];
    if (nodes.isEmpty) return issues;

    final idCounts = <String, int>{};
    final byId = <String, LearningPathNode>{};
    for (final n in nodes) {
      idCounts[n.id] = (idCounts[n.id] ?? 0) + 1;
      byId[n.id] = n;
    }

    for (final entry in idCounts.entries) {
      if (entry.value > 1) {
        issues.add(
          ValidationIssue(type: 'error', message: 'duplicate_id:${entry.key}'),
        );
      }
    }

    final startCount = idCounts['start'] ?? 0;
    if (startCount == 0) {
      issues.add(ValidationIssue(type: 'error', message: 'missing_start'));
    } else if (startCount > 1) {
      issues.add(ValidationIssue(type: 'error', message: 'multiple_start'));
    }

    for (final node in nodes) {
      if (node is LearningBranchNode) {
        if (node.branches.isEmpty) {
          issues.add(
            ValidationIssue(type: 'warning', message: 'no_branches:${node.id}'),
          );
        }
        for (final target in node.branches.values) {
          if (!byId.containsKey(target)) {
            issues.add(
              ValidationIssue(
                type: 'error',
                message: 'unknown_target:${node.id}:$target',
              ),
            );
          }
        }
      } else if (node is StageNode || node is TheoryLessonNode) {
        final nextIds = node is StageNode
            ? node.nextIds
            : (node as TheoryLessonNode).nextIds;
        if (node is StageNode) {
          for (final d in node.dependsOn) {
            if (!byId.containsKey(d)) {
              issues.add(
                ValidationIssue(
                  type: 'error',
                  message: 'unknown_dep:${node.id}:$d',
                ),
              );
            }
          }
        }
        for (final n in nextIds) {
          if (!byId.containsKey(n)) {
            issues.add(
              ValidationIssue(
                type: 'error',
                message: 'unknown_next:${node.id}:$n',
              ),
            );
          }
        }
      }
    }

    if (byId.containsKey('start')) {
      final reachable = <String>{};
      final queue = <String>['start'];
      while (queue.isNotEmpty) {
        final id = queue.removeAt(0);
        if (!reachable.add(id)) continue;
        final node = byId[id];
        if (node is LearningBranchNode) {
          queue.addAll(node.branches.values);
        } else if (node is StageNode) {
          queue.addAll(node.nextIds);
        } else if (node is TheoryLessonNode) {
          queue.addAll(node.nextIds);
        }
      }
      for (final n in nodes) {
        if (!reachable.contains(n.id)) {
          issues.add(
            ValidationIssue(type: 'warning', message: 'orphan:${n.id}'),
          );
        }
      }
    }

    final color = <String, int>{};
    final cycle = <String>{};

    bool dfs(String id) {
      final state = color[id] ?? 0;
      if (state == 1) {
        cycle.add(id);
        return true;
      }
      if (state == 2) return false;
      color[id] = 1;
      final node = byId[id];
      Iterable<String> next = [];
      if (node is LearningBranchNode) {
        next = node.branches.values;
      } else if (node is StageNode) {
        next = node.nextIds;
      } else if (node is TheoryLessonNode) {
        next = node.nextIds;
      }
      for (final n in next) {
        if (byId.containsKey(n) && dfs(n)) {
          cycle.add(id);
        }
      }
      color[id] = 2;
      return cycle.contains(id);
    }

    for (final id in byId.keys) {
      if (color[id] != 2) dfs(id);
    }

    for (final id in cycle) {
      issues.add(ValidationIssue(type: 'error', message: 'cycle:$id'));
    }

    return issues;
  }
}

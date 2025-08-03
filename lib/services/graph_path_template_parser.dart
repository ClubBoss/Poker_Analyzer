import 'package:yaml/yaml.dart';

import '../core/error_logger.dart';
import '../models/learning_branch_node.dart';
import '../models/learning_path_node.dart';
import '../models/stage_type.dart';
import '../models/theory_lesson_node.dart';
import '../models/theory_mini_lesson_node.dart';
import 'path_map_engine.dart';
import 'theory_track_engine.dart';
import '../utils/yaml_utils.dart';

class GraphPathTemplateParser {
  final List<String> warnings = [];

  Future<List<LearningPathNode>> parseFromYaml(String yamlText) async {
    final doc = loadYaml(yamlText);
    final map = doc is Map
        ? Map<String, dynamic>.from(yamlToDart(doc) as Map)
        : <String, dynamic>{};
    final nodesRaw = map['nodes'] as List? ?? [];

    await TheoryTrackEngine.instance.loadAll();

    final ids = <String>{};
    final rawItems = <Map<String, dynamic>>[];
    for (final n in nodesRaw) {
      if (n is Map) {
        final m = <String, dynamic>{};
        n.forEach((key, value) => m[key.toString()] = value);

        if (m.containsKey('include_track')) {
          final trackId = m['include_track'].toString();
          final track = TheoryTrackEngine.instance.get(trackId);
          if (track != null) {
            final generatedIds = <String>[];
            for (final b in track.blockIds) {
              var candidate = b;
              if (ids.contains(candidate)) {
                var i = 1;
                while (ids.contains('${candidate}#$i')) {
                  i++;
                }
                candidate = '${candidate}#$i';
              }
              generatedIds.add(candidate);
              ids.add(candidate);
            }
            for (var i = 0; i < track.blockIds.length; i++) {
              rawItems.add({
                'type': 'theory',
                'id': generatedIds[i],
                'refId': track.blockIds[i],
                if (i < generatedIds.length - 1) 'next': [generatedIds[i + 1]],
              });
            }
          }
        } else {
          final id = m['id']?.toString() ?? '';
          if (id.isNotEmpty) {
            ids.add(id);
          }
          rawItems.add(m);
        }
      }
    }

    final nodes = <LearningPathNode>[];
    final byId = <String, LearningPathNode>{};

    for (final m in rawItems) {
      final type = m['type']?.toString();
      final id = m['id']?.toString() ?? '';
      if (type == 'branch') {
        final branches = <String, String>{};
        final rawBranches = m['branches'];
        if (rawBranches is Map) {
          rawBranches.forEach((k, v) {
            branches[k.toString()] = v.toString();
          });
        }
        final node = LearningBranchNode(
          id: id,
          prompt: m['prompt']?.toString() ?? '',
          branches: branches,
          recoveredFromMistake: m['recoveredFromMistake'] as bool? ?? false,
        );
        nodes.add(node);
        byId[id] = node;
      } else if (type == 'stage') {
        final stageId = m['stageId']?.toString() ?? id;
        final nextIds = <String>[for (final v in (m['next'] as List? ?? [])) v.toString()];
        final dependsOn = <String>[for (final v in (m['dependsOn'] as List? ?? [])) v.toString()];
        final stageType = _parseStageType(m['stageType']);
        final recovered = m['recoveredFromMistake'] as bool? ?? false;
        final StageNode node = stageType == StageType.theory
            ? TheoryStageNode(
                id: stageId,
                nextIds: nextIds,
                dependsOn: dependsOn,
                recoveredFromMistake: recovered,
              )
            : TrainingStageNode(
                id: stageId,
                nextIds: nextIds,
                dependsOn: dependsOn,
                recoveredFromMistake: recovered,
              );
        nodes.add(node);
        byId[id] = node;
      } else if (type == 'theory') {
        final nextIds = <String>[for (final v in (m['next'] as List? ?? [])) v.toString()];
        final node = TheoryLessonNode(
          id: id,
          refId: m['refId']?.toString(),
          title: m['title']?.toString() ?? '',
          content: m['content']?.toString() ?? '',
          nextIds: nextIds,
          recoveredFromMistake: m['recoveredFromMistake'] as bool? ?? false,
        );
        nodes.add(node);
        byId[id] = node;
      } else if (type == 'mini') {
        final nextIds = <String>[for (final v in (m['next'] as List? ?? [])) v.toString()];
        final tags = <String>[for (final t in (m['tags'] as List? ?? [])) t.toString()];
        final node = TheoryMiniLessonNode(
          id: id,
          refId: m['refId']?.toString(),
          title: m['title']?.toString() ?? '',
          content: m['content']?.toString() ?? '',
          tags: tags,
          nextIds: nextIds,
          recoveredFromMistake: m['recoveredFromMistake'] as bool? ?? false,
        );
        nodes.add(node);
        byId[id] = node;
      }
    }

    for (final node in nodes) {
      if (node is LearningBranchNode) {
        for (final target in node.branches.values) {
          if (!ids.contains(target)) {
            warnings.add('Unknown node id $target referenced from branch ${node.id}');
          }
        }
      } else if (node is StageNode ||
          node is TheoryLessonNode ||
          node is TheoryMiniLessonNode) {
        final nextIds = node is StageNode
            ? node.nextIds
            : (node is TheoryLessonNode
                ? node.nextIds
                : (node as TheoryMiniLessonNode).nextIds);
        if (node is StageNode) {
          for (final d in node.dependsOn) {
            if (!ids.contains(d)) {
              warnings.add('Unknown node id $d referenced from dependsOn of ${node.id}');
            }
          }
        }
        for (final n in nextIds) {
          if (!ids.contains(n)) {
            warnings.add('Unknown node id $n referenced from nextIds of ${node.id}');
          }
        }
      }
    }

    if (nodes.isNotEmpty) {
      final reachable = <String>{};
      final queue = <String>[nodes.first.id];
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
        } else if (node is TheoryMiniLessonNode) {
          queue.addAll(node.nextIds);
        }
      }
      for (final id in ids.difference(reachable)) {
        warnings.add('Unreachable node $id');
      }
    }

    if (warnings.isNotEmpty) {
      for (final w in warnings) {
        ErrorLogger.instance.logError('GraphPathTemplateParser: $w');
      }
    }

    return nodes;
  }

  StageType _parseStageType(dynamic value) {
    final s = value?.toString();
    switch (s) {
      case 'theory':
        return StageType.theory;
      case 'booster':
        return StageType.booster;
    }
    return StageType.practice;
  }
}

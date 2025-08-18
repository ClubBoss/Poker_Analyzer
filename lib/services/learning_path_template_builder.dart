import 'dart:io';

import '../core/training/generation/yaml_reader.dart';
import '../models/learning_path_template_v2.dart';
import '../core/training/library/training_pack_library_v2.dart';

class LearningPathTemplateBuilder {
  static LearningPathTemplateV2 fromYamlFile(String yamlPath) {
    final file = File(yamlPath);
    if (!file.existsSync()) {
      throw Exception('file not found: $yamlPath');
    }
    final raw = file.readAsStringSync();
    final map = const YamlReader().read(raw);
    return LearningPathTemplateV2.fromJson(Map<String, dynamic>.from(map));
  }

  static void validate(LearningPathTemplateV2 template) {
    final errors = <String>[];
    final ids = <String>{};
    for (final s in template.stages) {
      if (!ids.add(s.id)) errors.add('duplicate_stage_id:${s.id}');
    }
    for (final s in template.stages) {
      for (final u in s.unlocks) {
        if (!ids.contains(u)) {
          errors.add('bad_unlock:${s.id}->$u');
        }
      }
    }
    final packIds = {
      for (final p in TrainingPackLibraryV2.instance.packs) p.id,
    };
    for (final s in template.stages) {
      if (!packIds.contains(s.packId)) {
        errors.add('missing_pack:${s.packId}');
      }
    }
    final cycle = checkForCycles(template);
    if (cycle.isNotEmpty) errors.add('cycle:${cycle.join('->')}');
    if (errors.isNotEmpty) throw FormatException(errors.join(', '));
  }

  static List<String> checkForCycles(LearningPathTemplateV2 template) {
    final graph = <String, List<String>>{};
    for (final s in template.stages) {
      graph[s.id] = List<String>.from(s.unlocks);
    }
    final visited = <String>{};
    final stack = <String>[];
    final cycle = <String>[];

    bool dfs(String node) {
      if (stack.contains(node)) {
        cycle.add(node);
        return true;
      }
      if (visited.contains(node)) return false;
      visited.add(node);
      stack.add(node);
      for (final next in graph[node] ?? const <String>[]) {
        if (dfs(next)) {
          if (cycle.isNotEmpty && cycle.first != node) cycle.add(node);
          return true;
        }
      }
      stack.removeLast();
      return false;
    }

    for (final id in graph.keys) {
      if (dfs(id)) break;
    }
    return cycle.reversed.toList();
  }
}

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';

import '../main.dart';
import '../models/learning_branch_node.dart';
import '../models/learning_path_node.dart';
import '../models/theory_lesson_node.dart';
import 'graph_path_template_parser.dart';
import 'graph_template_library.dart';
import 'path_map_engine.dart';

/// Exports graph templates to YAML files.
class GraphTemplateExporter {
  final GraphPathTemplateParser parser;

  GraphTemplateExporter({GraphPathTemplateParser? parser})
    : parser = parser ?? GraphPathTemplateParser();

  /// Converts [nodes] into a YAML string.
  String encodeNodes(List<LearningPathNode> nodes) {
    final list = [for (final n in nodes) _nodeMap(n)];
    return const YamlEncoder().convert({'nodes': list});
  }

  /// Saves the template with [templateId] as a YAML file chosen by the user.
  /// If [saveToFile] is `false`, the YAML string is returned without writing
  /// to disk.
  Future<String?> exportTemplate(
    String templateId, {
    bool saveToFile = true,
  }) async {
    final raw = GraphTemplateLibrary.instance.getTemplate(templateId);
    if (raw.isEmpty) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(const SnackBar(content: Text('Template not found')));
      }
      return null;
    }

    final nodes = await parser.parseFromYaml(raw);
    final yaml = encodeNodes(nodes);

    if (!saveToFile) return yaml;

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Graph Template',
      fileName: '$templateId.yaml',
      type: FileType.custom,
      allowedExtensions: ['yaml'],
    );
    if (savePath == null) return yaml;

    try {
      await File(savePath).writeAsString(yaml, flush: true);
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        final name = savePath.split(Platform.pathSeparator).last;
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(SnackBar(content: Text('Exported: $name')));
      }
    } catch (_) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Failed to export template')),
        );
      }
    }
    return yaml;
  }

  Map<String, dynamic> _nodeMap(LearningPathNode node) {
    if (node is LearningBranchNode) {
      return {
        'type': 'branch',
        'id': node.id,
        'prompt': node.prompt,
        if (node.branches.isNotEmpty) 'branches': node.branches,
      };
    } else if (node is TheoryLessonNode) {
      return {
        'type': 'theory',
        'id': node.id,
        if (node.refId != null) 'refId': node.refId,
        'title': node.title,
        'content': node.content,
        if (node.nextIds.isNotEmpty) 'next': node.nextIds,
      };
    } else if (node is StageNode) {
      final stageType = node is TheoryStageNode ? 'theory' : 'practice';
      return {
        'type': 'stage',
        'id': node.id,
        if (stageType != 'practice') 'stageType': stageType,
        if (node.nextIds.isNotEmpty) 'next': node.nextIds,
        if (node.dependsOn.isNotEmpty) 'dependsOn': node.dependsOn,
      };
    }
    return {'id': node.id};
  }
}

import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:yaml/yaml.dart';

import '../models/theory_mini_lesson_node.dart';

/// Utility to create [TheoryMiniLessonNode] objects or YAML fragments
/// from short text snippets.
class MiniLessonNodeBuilder {
  final Uuid _uuid;

  const MiniLessonNodeBuilder({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  /// Generates a unique identifier using [tag] as prefix.
  String _generateId(String tag) {
    final safeTag = tag.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]+'), '_');
    return '${safeTag}_${_uuid.v4()}';
  }

  /// Builds a new [TheoryMiniLessonNode].
  TheoryMiniLessonNode build({
    required String tag,
    required String title,
    required String content,
    List<String>? nextIds,
    bool autoContent = false,
  }) {
    return TheoryMiniLessonNode(
      id: _generateId(tag),
      title: title,
      content: content,
      tags: [tag],
      nextIds: nextIds ?? const [],
      autoContent: autoContent,
    );
  }

  /// Returns a YAML compatible map for serialization.
  Map<String, dynamic> toYamlMap({
    required String tag,
    required String title,
    required String content,
    List<String>? nextIds,
    int? priority,
    List<String>? examples,
    bool autoContent = false,
  }) {
    final node = build(
      tag: tag,
      title: title,
      content: content,
      nextIds: nextIds,
      autoContent: autoContent,
    );
    final map = <String, dynamic>{
      'id': node.id,
      'title': node.title,
      'content': node.content,
      'tags': node.tags,
      if (node.nextIds.isNotEmpty) 'next': node.nextIds,
      'type': 'mini',
    };
    if (priority != null) map['priority'] = priority;
    if (examples != null && examples.isNotEmpty) map['examples'] = examples;
    if (autoContent) map['autoContent'] = true;
    return map;
  }

  /// Encodes the node to a YAML string.
  String toYaml({
    required String tag,
    required String title,
    required String content,
    List<String>? nextIds,
    int? priority,
    List<String>? examples,
    bool autoContent = false,
  }) {
    final map = toYamlMap(
      tag: tag,
      title: title,
      content: content,
      nextIds: nextIds,
      priority: priority,
      examples: examples,
      autoContent: autoContent,
    );
    return const YamlEncoder().convert(map);
  }

  /// Encodes the node to a JSON string.
  String toJson({
    required String tag,
    required String title,
    required String content,
    List<String>? nextIds,
    int? priority,
    List<String>? examples,
    bool autoContent = false,
  }) {
    final map = toYamlMap(
      tag: tag,
      title: title,
      content: content,
      nextIds: nextIds,
      priority: priority,
      examples: examples,
      autoContent: autoContent,
    );
    return jsonEncode(map);
  }
}

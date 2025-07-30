import 'learning_path_node.dart';
import '../services/theory_content_service.dart';

/// Node representing a short theory mini lesson within the learning path graph.
class TheoryMiniLessonNode implements LearningPathNode {
  @override
  final String id;

  /// Optional reference id of shared theory content.
  final String? refId;

  /// Display title of the lesson.
  final String title;

  /// Markdown or plain text content of the lesson.
  final String content;

  /// Tags associated with this mini lesson.
  final List<String> tags;

  /// Optional stage identifier like `level2`.
  final String? stage;

  /// IDs of nodes unlocked after reading this lesson.
  final List<String> nextIds;

  /// Ids of training packs linked to this lesson.
  List<String> linkedPackIds;

  const TheoryMiniLessonNode({
    required this.id,
    this.refId,
    required this.title,
    required this.content,
    this.stage,
    List<String>? tags,
    List<String>? nextIds,
    List<String>? linkedPackIds,
  })  : tags = tags ?? const [],
        nextIds = nextIds ?? const [],
        linkedPackIds = linkedPackIds ?? const [];

  /// Returns [title] or the referenced block's title when empty.
  String get resolvedTitle {
    if (title.isNotEmpty) return title;
    if (refId == null) return title;
    final block = TheoryContentService.instance.get(refId!);
    return block?.title ?? title;
  }

  /// Returns [content] or the referenced block's content when empty.
  String get resolvedContent {
    if (content.isNotEmpty) return content;
    if (refId == null) return content;
    final block = TheoryContentService.instance.get(refId!);
    return block?.content ?? content;
  }

  factory TheoryMiniLessonNode.fromYaml(Map yaml) {
    final tags = <String>[];
    final rawTags = yaml['tags'];
    if (rawTags is List) {
      for (final t in rawTags) {
        tags.add(t.toString());
      }
    }
    final nextIds = <String>[for (final v in (yaml['next'] as List? ?? [])) v.toString()];
    final linked = <String>[for (final v in (yaml['linkedPackIds'] as List? ?? [])) v.toString()];
    return TheoryMiniLessonNode(
      id: yaml['id']?.toString() ?? '',
      refId: yaml['refId']?.toString(),
      title: yaml['title']?.toString() ?? '',
      content: yaml['content']?.toString() ?? '',
      tags: tags,
      stage: yaml['stage']?.toString(),
      nextIds: nextIds,
      linkedPackIds: linked,
    );
  }
}

import 'learning_path_node.dart';
import '../services/theory_content_service.dart';

/// Node representing an inline theory lesson within the learning path graph.
class TheoryLessonNode implements LearningPathNode {
  @override
  final String id;

  /// Optional reference id of shared theory content.
  final String? refId;

  /// Display title of the lesson.
  final String title;

  /// Markdown or plain text content of the lesson.
  final String content;

  /// IDs of nodes unlocked after reading this lesson.
  final List<String> nextIds;

  const TheoryLessonNode({
    required this.id,
    this.refId,
    required this.title,
    required this.content,
    List<String>? nextIds,
  }) : nextIds = nextIds ?? const [];

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
}

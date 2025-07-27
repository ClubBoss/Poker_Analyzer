import 'learning_path_node.dart';

/// Node representing an inline theory lesson within the learning path graph.
class TheoryLessonNode implements LearningPathNode {
  @override
  final String id;

  /// Display title of the lesson.
  final String title;

  /// Markdown or plain text content of the lesson.
  final String content;

  /// IDs of nodes unlocked after reading this lesson.
  final List<String> nextIds;

  const TheoryLessonNode({
    required this.id,
    required this.title,
    required this.content,
    List<String>? nextIds,
  }) : nextIds = nextIds ?? const [];
}

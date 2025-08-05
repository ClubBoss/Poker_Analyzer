import 'theory_mini_lesson_node.dart';

class TheoryLessonCluster {
  final List<TheoryMiniLessonNode> lessons;
  final Set<String> sharedTags;

  const TheoryLessonCluster({
    required this.lessons,
    required Set<String> tags,
  }) : sharedTags = tags;

  @Deprecated('Use sharedTags')
  Set<String> get tags => sharedTags;
}

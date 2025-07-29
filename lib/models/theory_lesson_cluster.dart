import 'theory_mini_lesson_node.dart';

class TheoryLessonCluster {
  final List<TheoryMiniLessonNode> lessons;
  final Set<String> tags;

  const TheoryLessonCluster({
    required this.lessons,
    required this.tags,
  });
}

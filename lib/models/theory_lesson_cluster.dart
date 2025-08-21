import 'theory_mini_lesson_node.dart';

class TheoryLessonCluster {
  final List<TheoryMiniLessonNode> lessons;
  final Set<String> sharedTags;

  /// Tags automatically inferred from the lessons within this cluster.
  ///
  /// Populated by [TheoryLessonClusterAutoTagger].
  List<String> autoTags;

  TheoryLessonCluster({
    required this.lessons,
    required Set<String> tags,
    List<String>? autoTags,
  })  : sharedTags = tags,
        autoTags = autoTags ?? [];

  @Deprecated('Use sharedTags')
  Set<String> get tags => sharedTags;
}
